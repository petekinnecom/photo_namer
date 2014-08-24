require 'rubygems'
require 'pry'

class PhotoRenamer
  def self.run
    new.run
  end

  FILES_REGEX = /\.jpg$|\.JPG$|\.mp4$|\.3gp$/

  attr_reader :origin_dir, :destination_dir
  def initialize
    @origin_dir = ARGV[0]
    @destination_dir = ARGV[1]

    raise "Can't find photo dir" unless Dir.exists?(origin_dir)
    raise "Please give a destination directory" unless destination_dir
    raise "Please create destination destiny manually" unless Dir.exists?(destination_dir)
  end

  def run
    source_photos.each do |source_photo|
      PhotoCopier.process(source_photo, destination_dir)
    end
  end

  private

  def source_photos
    matching_filenames.map do |filename|
      SourcePhotoFile.new(origin_dir, filename)
    end
  end

  def matching_filenames
    Dir.entries(origin_dir).select {|f| f.match(FILES_REGEX) }
  end

end

class SourcePhotoFile
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

  def exif_date_string
    `exiftool -CreateDate #{full_path}`
  end

  def extension
    File.extname(filename)
  end
end

class DestinationFile
  attr_reader :directory, :extension, :filename, :counter, :source_photo

  def initialize(directory, source_photo)
    @directory = directory
    @extension = source_photo.extension
    @filename = source_photo.datetime
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

end

class PhotoCopier
  def self.process(source_photo, destination_dir)
    new(source_photo, destination_dir).process
  end

  attr_reader :renamed_photo, :source_photo
  def initialize(source_photo, destination_dir)
    @renamed_photo = DestinationFile.new(destination_dir, source_photo)
    @source_photo = source_photo
  end

  def process
    if renamed_photo.binary_duplicate_exists?
      puts "\nFile is already in destination: #{source_photo.filename}. Not copying"
    else
      while renamed_photo.name_taken?
        renamed_photo.increment_counter
        puts "\nFile: #{renamed_photo.filename} already exists.  Appending a counter."
      end
    end

    FileUtils.copy(source_photo.full_path, renamed_photo.full_path)
    print '.'
  end
end

PhotoRenamer.run
