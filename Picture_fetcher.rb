require "fileutils"
require "io/console"

module PictureFetcher

	class Fetcher

		def initialize source_dir, images_target_dir, movies_target_dir, mode
			@source_dir = source_dir
			@images_target_dir = images_target_dir
			@movies_target_dir = movies_target_dir
			@mode = mode
			@number_of_digits = 4
		end

		def fetch
			puts "Picture Fetcher"
			puts "Source directory: #{@source_dir}"
			puts "Target directory for images: #{@images_target_dir}"
			puts "Target directory for movies: #{@movies_target_dir}"

			images = Dir.glob("#{@source_dir}/**/*").select{|f| f.downcase.end_with?(".png") || f.downcase.end_with?(".jpeg") || f.downcase.end_with?(".jpg") || f.downcase.end_with?(".nef")}.sort{ |x, y| x <=> y }
			movies = Dir.glob("#{@source_dir}/**/*").select{|f| f.downcase.end_with?(".mov") || f.downcase.end_with?(".mp4") || f.downcase.end_with?(".avi")}.sort{ |x, y| x <=> y }

			puts "Found #{images.length} images and #{movies.length} movies"

			files_to_delete = []

			files_to_delete += copy_files images, @images_target_dir
			files_to_delete += copy_files movies, @movies_target_dir

			delete_files(files_to_delete)
			
			puts "Done."
		end

		def calculate_image_index(path, file_prefix)
			index = 0
			Dir.entries(path).select{|f| f.start_with?(file_prefix)}.each do |f|
				number = f[file_prefix.length,@number_of_digits].to_i
				index = number if number > index
			end
			return index + 1
		end

		def create_directories_and_return_file_name(target_dir, original_file_name, date)
			year = sprintf("%4d", date.year)
			month = sprintf("%02d", date.mon)
			day = sprintf("%02d", date.mday)

			year_dir = "#{target_dir}/#{year}"
			month_dir = "#{year_dir}/#{year}-#{month}"
			day_dir = "#{month_dir}/#{year}-#{month}-#{day}"

			if (!Dir.exist?(year_dir))
				puts "Creating #{year_dir}"
				Dir.mkdir(year_dir)
			end
			if (!Dir.exist?(month_dir))
				puts "Creating #{month_dir}"
				Dir.mkdir(month_dir)
			end
			if (!Dir.exist?(day_dir))
				puts "Creating #{day_dir}"
				Dir.mkdir(day_dir)
			end

			file_prefix = "#{year}-#{month}-#{day} "
			file_extension = File.extname(original_file_name).downcase
			original_file_name_infix = File.basename(original_file_name, ".*")
			index = calculate_image_index(day_dir, file_prefix)
			index_str = sprintf("%0#{@number_of_digits}d", index)
			file_name = "#{day_dir}/#{year}-#{month}-#{day} #{index_str} (#{original_file_name_infix})#{file_extension}"
			return file_name
		end

		def copy_files(files, target_dir)
			files_to_delete = []
			files.each do |file|
				attempt = 0
				success = false

				while attempt <= 3 && success == false do
					attempt += 1
					begin
						date = File.ctime(file)
						if @mode == "M"
							date = File.mtime(file)
						end
						year = date.year
						month = date.month
						day = date.day
						target_file = create_directories_and_return_file_name(target_dir, File.basename(file), date)
						puts "Copying #{file} to #{target_file} (attempt #{attempt})"
						FileUtils.cp(file, target_file)
						files_to_delete << file
						success = true
					rescue Exception => ex
						puts "Failed to copy #{file} to #{target_file}: {ex}"
						success = false
					end
				end
			end
			return files_to_delete
		end

		def delete_files(files)
			files.each do |file|
				puts "Deleting file #{file}"
				File.delete(file)
			end
		end
	end
end

source_dir = "k:/"

if ARGV.length > 0
	source_dir = ARGV[0].gsub(/\\/,"/")
end

if ARGV.length > 1
	mode = ARGV[1]
end

puts source_dir

target_dir_images = "d:/clouds/OneDrive/import/zdjecia/"
target_dir_movies = "d:/clouds/OneDrive/import/filmy/"

Dir.mkdir(target_dir_images) if !Dir.exist?(target_dir_images)
Dir.mkdir(target_dir_movies) if !Dir.exist?(target_dir_movies)

fetcher = PictureFetcher::Fetcher.new source_dir, target_dir_images, target_dir_movies, mode
fetcher.fetch