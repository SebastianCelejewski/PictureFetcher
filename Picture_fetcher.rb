require "fileutils"
require "io/console"

module PictureFetcher

	class Fetcher

		def initialize source_dir, images_target_dir, movies_target_dir
			@source_dir = source_dir
			@images_target_dir = images_target_dir
			@movies_target_dir = movies_target_dir
			@number_of_digits = 4
		end

		def fetch
			puts "Picture Fetcher"
			puts "Source directory: #{@source_dir}"
			puts "Target directory for images: #{@images_target_dir}"
			puts "Target directory for movies: #{@movies_target_dir}"

			images = Dir.glob("#{@source_dir}/**/*").select{|f| f.end_with?(".JPG")}
			movies = Dir.glob("#{@source_dir}/**/*").select{|f| f.end_with?(".MOV")}

			puts "Found #{images.length} images and #{movies.length} movies"

			copy_files images, @images_target_dir
			copy_files movies, @movies_target_dir

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

		def create_directories_and_return_file_name(target_dir, file_name, date)
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
			file_extension = File.extname(file_name).downcase
			index = calculate_image_index(day_dir, file_prefix)
			index_str = sprintf("%0#{@number_of_digits}d", index)
			file_name = "#{day_dir}/#{year}-#{month}-#{day} #{index_str}#{file_extension}"
			return file_name
		end

		def copy_files(files, target_dir)
			files.each do |file|
				cdate = File.ctime(file)
				year = cdate.year
				month = cdate.month
				day = cdate.day
				target_file = create_directories_and_return_file_name(target_dir, File.basename(file), cdate)
				puts "Copying #{file} to #{target_file}"
				FileUtils.copy(file, target_file)
			end
		end

	end

end

source_dir = "f:/"
target_dir_images = "d:/pictures"
target_dir_movies = "d:/movies"

Dir.mkdir(target_dir_images) if !Dir.exist?(target_dir_images)
Dir.mkdir(target_dir_movies) if !Dir.exist?(target_dir_movies)

fetcher = PictureFetcher::Fetcher.new source_dir, target_dir_images, target_dir_movies
fetcher.fetch