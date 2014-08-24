require 'rubygems'
require 'pry'

  UnNameableFileError = Class.new(StandardError)
  SkippableFileError = Class.new(StandardError)

class PhotoFile
  attr_reader :dir, :name, :extension, :name_with_extension, :full_path

  def initialize(dir, name, extension)
    @dir = dir
    @name = name
    @extension = extension
    @name_with_extension = "#{@name}#{@extension}"
    @full_path = "#{@dir}/#{@name_with_extension}"
  end

  def to_s
    self.name_with_extension
  end

  def destination_file(destination_dir)
    begin
      # THIS IS A MESS
      #
      #
      #
      #
      # CLEAN THIS UP
      #
      #
      #
      # handle errors not in here
      datetime = exif_date_string.sub(/Create Date\s+:/, '').chomp.strip
      date, time = datetime.split(/ /)
      date.gsub!(':', '-')
      time.gsub!(':', '.')

      filename = "#{date} #{time}"

      if File.exists?("#{destination_dir}/#{filename}#{self.extension}")
        raise SkippableFileError if FileUtils.compare_file("#{self.full_path}", "#{destination_dir}/#{filename}#{self.extension}")
      end

      counter = 2
      while File.exists?("#{destination_dir}/#{filename}#{self.extension}")
        if ! File.exists?("#{destination_dir}/#{filename} #{counter}#{self.extension}")
          puts "\nFile: #{filename}#{self.extension} already exists.  Appending a counter."
          filename = "#{filename} #{counter}"
        end
        counter += 1
      end

      "#{filename}#{self.extension}"
    rescue SkippableFileError => e
      raise SkippableFileError
    rescue Exception => e
      raise UnNameableFileError.new('')
    end
  end

  def exif_date_string
    `exiftool -CreateDate #{self.full_path}`
  end
end

class PhotoNamer
  FILES_REGEX = /\.jpg$|\.JPG$|\.mp4$|\.3gp$/
  attr_reader :origin_dir, :destination_dir, :photos

  def initialize
    @origin_dir = ARGV[0]
    @destination_dir = ARGV[1]

    raise "Can't find photo dir" unless Dir.exists?(origin_dir)
    raise "Please give a destination directory" unless destination_dir
    raise "Please create destination destiny manually" unless Dir.exists?(destination_dir)

    @photos = find_photos
  end

  def run
    photos.each do |origin_photo|
      PhotoCopier.process(origin_photo, origin_dir, destination_dir)
    end
  end

  private

  def find_photos
    filenames = Dir.entries(origin_dir).select {|f| f.match(FILES_REGEX) }

    filenames.map do |name|
      name_without_extension = name.gsub(/#{File.extname(name)}$/, '')
      extension = File.extname(name).downcase

      PhotoFile.new(origin_dir, name_without_extension, extension)
    end
  end

  class PhotoCopier

    def self.process(photo, origin_dir, destination_dir)
      new(photo, origin_dir, destination_dir).process
    end

    attr_reader :origin_photo, :origin_dir, :destination_dir
    def initialize(photo, origin_dir, destination_dir)
      @origin_photo = photo
      @origin_dir = origin_dir
      @destination_dir = destination_dir
    end

    def process
      begin
        destination_file = origin_photo.destination_file(destination_dir)
        copy(origin_photo.full_path, "#{destination_dir}/#{destination_file}")
        printf '.'
      rescue UnNameableFileError => e
        puts "\nCould not process #{origin_photo}. Copying without renaming."
        copy(origin_photo.full_path, "#{destination_dir}/#{origin_photo.name_with_extension}")
      rescue SkippableFileError => e
        puts "\nFile is already in destination #{origin_photo}. Not copying"
      end
    end

    def copy(original_file, destination_file)
      if File.exists?(destination_file) && FileUtils.compare_file(original_file, destination_file)
        puts "\nFile is already in destination. Not copying : #{original_file}"
      else
        `cp '#{original_file}' '#{destination_file}'`
        printf '.'
      end
    end


  end
end

PhotoNamer.new.run


