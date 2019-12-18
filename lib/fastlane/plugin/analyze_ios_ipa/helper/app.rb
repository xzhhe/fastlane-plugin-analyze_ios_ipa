require 'fastlane_core/ui/ui'
module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    require_relative 'info_plist'
    require_relative 'ipa'
    require_relative 'file_info'
    require_relative 'file_category'

    class App
      ATTRS = [:size, :formar_size, :info, :files, :file_infos, :executable, :bundles, :frameworks, :categories]
      attr_accessor(*ATTRS)

      def to_hash
        {
          size:        @size,
          formar_size: @formar_size,
          info: {
            executable:          @info.executable,
            device_capabilities: @info.device_capabilities,
            app_type:            @info.app_type, #=> 只有自己项目使用
            identifier:          @info.identifier,
            display_name:        @info.display_name,
            version:             @info.version,
            short_version:       @info.short_version
          },
          categories: @categories.map(&:to_hash)
        }
      end

      def initialize(app_path)
        @app_path = app_path

        return nil unless app_path
        return nil if app_path.empty?
        return nil unless File.exist?(app_path)

        # size
        @size        = FileHelper.file_size(app_path)
        @formar_size = FileHelper.format_size(@size)

        # info.plist
        info_plist_path = File.expand_path('Info.plist', app_path)
        @info = InfoPlist.new(info_plist_path)

        # files
        parse_files
      end

      def parse_files
        return @categories if @categories

        @files = FileHelper.glob_files('*', @app_path)
        # pp @files

        @file_infos = files.map {|f|
          FileInfo.new(f)
        }
        # pp @file_infos

        goruped_file_infos = @file_infos.group_by { |e|
          e.type
        }
        # pp goruped_file_infos

        categories = []
        categories.concat(goruped_file_infos.map { |k ,v|
          FileCategory.categories(k, v, executable: @info.executable)
        }.compact.flatten)
        # pp categories.count
        # pp categories

        # 去除 name == 'Unknown' 重复的 FileCategory
        categories_rejected = categories.reject { |c|
          c.name == 'Unknown'
        }
        # pp categories_reject.count

        categories_rejecting = categories.select { |c|
          c.name == 'Unknown'
        }
        # pp categories_rejecting

        unknown_files_infos = []
        categories_rejecting.each_with_object(unknown_files_infos) { |e, o|
          unknown_files_infos.concat(e.file_infos).compact.flatten
        }
        unknown_files_infos.uniq! { |e| e.name }
        unknown_category = FileCategory.categories('UnknownFiles', unknown_files_infos)
        # pp unknown_category

        categories_rejected.push(unknown_category)
        # pp categories_rejected.count
        # pp categories_rejected
        @categories = categories_rejected
      end

      def generate_json
        return @result_json if @result_json
        @result_json = JSON.generate(generate_hash)
        @result_json
      end

      def generate_hash
        return @result_hash if @result_hash
        @result_hash = to_hash
        @result_hash
      end
    end
  end
end
