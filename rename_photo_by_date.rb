require 'rubygems'
require 'pry'


class PhotoNamer
  FILES_REGEX = /\.jpg$|\.mp4$|\.3gp$/
  attr_reader :origin_dir, :destination_dir, :files

  UnNameableFileError = Class.new(StandardError)

  def run
    find_files
    files.each do |origin_file|
      begin
        destination_file = create_new_file_name(origin_file)

        `cp '#{origin_dir}/#{origin_file}' '#{destination_dir}/#{destination_file}'`
        printf '.'
      rescue UnNameableFileError => e
        puts "\nCould not process #{origin_file}. Copying without renaming."
        `cp '#{origin_dir}/#{origin_file}' '#{destination_dir}/#{origin_file}'`
      end
    end
  end

  private

  def find_files
    @origin_dir = ARGV[0]
    @destination_dir = ARGV[1]
    raise "Can't find photo dir" unless Dir.exists?(origin_dir)
    raise "Please give a destination directory" unless destination_dir
    raise "Please create destination destiny manually" unless Dir.exists?(destination_dir)
    @files = Dir.entries(origin_dir).select {|f| f.match(FILES_REGEX) }
  end

  def create_new_file_name(origin_file)
    begin
      exif_date_string = `exiftool -CreateDate #{origin_dir}/#{origin_file}`
      datetime = exif_date_string.sub(/Create Date\s+:/, '').chomp.strip
      date, time = datetime.split(/ /)
      date.gsub!(':', '-')
      time.gsub!(':', '.')

      filename = "#{date} #{time}"

      counter = 2
      while File.exists?("#{destination_dir}/#{filename}#{File.extname(origin_file)}")
        if ! File.exists?("#{destination_dir}/#{filename} #{counter}#{File.extname(origin_file)}")
          filename = "#{filename} #{counter}"
        end
        counter += 1
      end

      "#{filename}#{File.extname(origin_file)}"
    rescue Exception => e
      raise UnNameableFileError.new('')
    end
  end
end

PhotoNamer.new.run


