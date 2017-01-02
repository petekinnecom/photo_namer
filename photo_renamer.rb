require 'fileutils'
require 'time'
require 'shellwords'

class PhotoRenamer
  def self.run
    new.run
  end

  FILES_REGEX = /\.jpg$|\.mp4$|\.3gp$/i

  attr_reader :source_dir, :destination_dir, :failure_dir
  def initialize
    @source_dir = ARGV[0].gsub(/\/$/, '')
    @destination_dir = ARGV[1].gsub(/\/$/, '')
    @failure_dir = ARGV[2].gsub(/\/$/, '')

    ARGV.each_with_index {|a, i| puts "#{i}: #{a}"}

    raise "Can't find photo dir" unless Dir.exists?(source_dir)
    raise "Please give a destination directory" unless destination_dir
    raise "Please create destination directory manually" unless Dir.exists?(destination_dir)

    if failure_dir
      raise "Please create failure directory manually" unless Dir.exists?(failure_dir)
    end
  end

  def run
    source_photos.each do |source_photo|
      begin
        PhotoCopier.process(source_photo, destination_dir)
      rescue Exception => e
        puts "\nThere was an error while copying #{source_photo.full_path}:"
        puts e.message
        if failure_dir
          FileUtils.copy(source_photo.full_path, "#{failure_dir}/#{source_photo.filename}")
          puts "#{source_photo.full_path} --> #{failure_dir}/#{source_photo.filename}"
        else
          exit 1
        end
      end
    end
  end

  private

  def source_photos
    matching_filenames.map do |filename|
      SourcePhoto.new(source_dir, filename)
    end
  end

  def matching_filenames
    Dir.entries(source_dir).select {|f| f.match(FILES_REGEX) }
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
    @datetime ||= begin
      datetime = exif_date_string.sub(/Create Date\s+:/, '').chomp.strip
      date, time = datetime.split(/ /)
      date.gsub!(':', '-')
      timestamp = Time.parse("#{date} #{time}")

      timestamp.strftime("%Y-%m-%d %H.%M.%S")
    end
  end

  def extension
    File.extname(filename).downcase
  end

  private

  def exif_date_string
    `exiftool -CreateDate #{Shellwords.escape(full_path)}`
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
