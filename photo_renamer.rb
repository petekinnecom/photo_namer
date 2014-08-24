require 'rubygems'
require 'pry'

class PhotoRenamer
  def self.run
    new.run
  end

  FILES_REGEX = /\.jpg$|\.JPG$|\.mp4$|\.3gp$/

  attr_reader :origin_dir, :destination_dir
  def initialize
    @origin_dir = ARGV[0].gsub(/\/$/, '')
    @destination_dir = ARGV[1].gsub(/\/$/, '')

    raise "Can't find photo dir" unless Dir.exists?(origin_dir)
    raise "Please give a destination directory" unless destination_dir
    raise "Please create destination destiny manually" unless Dir.exists?(destination_dir)
  end

  def run
    source_photos.each do |source_photo|
      begin
        PhotoCopier.process(source_photo, destination_dir)
      rescue Exception => e
        puts "\nThere was an error while copying #{source_photo.full_path}:"
        puts e.message
        exit 1
      end
    end
  end

  private

  def source_photos
    matching_filenames.map do |filename|
      SourcePhoto.new(origin_dir, filename)
    end
  end

  def matching_filenames
    Dir.entries(origin_dir).select {|f| f.match(FILES_REGEX) }
  end

end

class SourcePhoto
  SkippableFileError = Class.new(StandardError)

  attr_reader :directory, :filename
  def initialize(directory, filename)
    @directory = directory
    @filename = filename
  end

  def full_path
    "#{directory}/#{filename}"
  end

  def datetime
    datetime = exif_date_string.sub(/Create Date\s+:/, '').chomp.strip
    date, time = datetime.split(/ /)
    date.gsub!(':', '-')
    time.gsub!(':', '.')

    "#{date} #{time}"
  end

  def extension
    File.extname(filename)
  end

  private

  def exif_date_string
    `exiftool -CreateDate #{full_path}`
  end
end

class RenamedPhoto
  attr_reader :directory, :source_photo, :counter

  def initialize(directory, source_photo)
    @directory = directory
    @source_photo = source_photo
    @counter = ''
  end

  def increment_counter
    if @counter == ''
      @counter = ' 2'
    else
      @counter = " #{@counter.to_i + 1}"
    end
  end

  def full_path
    "#{directory}/#{filename}#{counter}#{extension}"
  end

  def binary_duplicate_exists?
    name_taken? && FileUtils.compare_file(source_photo.full_path, full_path)
  end

  def name_taken?
    File.exists?(full_path)
  end

  def filename
    source_photo.datetime
  end

  def extension
    source_photo.extension
  end
end

class PhotoCopier
  def self.process(source_photo, destination_dir)
    new(source_photo, destination_dir).process
  end

  attr_reader :renamed_photo, :source_photo
  def initialize(source_photo, destination_dir)
    @source_photo = source_photo
    @renamed_photo = RenamedPhoto.new(destination_dir, source_photo)
  end

  def process
    return if nothing_to_copy_because_of_duplicate
    increment_counter_if_necessary
    copy_file
  end

  def nothing_to_copy_because_of_duplicate
    if renamed_photo.binary_duplicate_exists?
      puts "File is already in destination: #{source_photo.filename}. Not copying"
      return true
    end
  end

  def increment_counter_if_necessary
    while renamed_photo.name_taken?
      renamed_photo.increment_counter
      puts "File: #{renamed_photo.filename} already exists.  Appending a counter."
    end
  end

  def copy_file
    FileUtils.copy(source_photo.full_path, renamed_photo.full_path)
    puts "#{source_photo.full_path} --> #{renamed_photo.full_path}"
  end
end

PhotoRenamer.run
