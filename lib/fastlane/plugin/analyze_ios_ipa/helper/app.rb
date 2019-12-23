require 'fastlane_core/ui/ui'
module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    require_relative 'info_plist'
    require_relative 'ipa'
    require_relative 'file_info'
    require_relative 'file_category'

    class App
      ATTRS = [:group, :size, :format_size, :info, :executable]
      attr_accessor(*ATTRS)
      alias group? group


      INFO_PLIST = 'Info.plist'

      def to_hash
        h = {
          size:        @size,
          format_size: @format_size,
          info: {
            executable:          @info.executable,
            device_capabilities: @info.device_capabilities,
            app_type:            @info.app_type, #=> 只有自己项目使用
            identifier:          @info.identifier,
            display_name:        @info.display_name,
            version:             @info.version,
            short_version:       @info.short_version
          }
        }

        if group?
          h[:categories] = categories.map(&:to_hash)
        else
          h[:files]      = parse_app_files.map(&:to_hash)
        end

        h
      end

      def initialize(app_path, options = {})
        @group    = options[:group] || false
        @app_path = app_path

        return nil unless app_path
        return nil if app_path.empty?
        return nil unless File.exist?(app_path)

        # size
        @size        = FileHelper.file_size(app_path)
        @format_size = FileHelper.format_size(@size)

        # info.plist
        info_plist_path = File.expand_path(INFO_PLIST, app_path)
        @info = InfoPlist.new(info_plist_path)
      end

      def parse_app_files
        return @files if @files

        files = FileHelper.glob_files('*', @app_path)
        # pp files
        return nil unless files
        return nil if files.empty?

        #
        # 解析 具体文件 => FileInfo
        @file_infos = files.map {|f|
          FileInfo.new(f)
        }
        @file_infos
      end

      def group_app_files
        return @group_app_files if @group_app_files

        #
        # 按照 type 对 [#<FileInfo:0x01>, #<FileInfo:0x02>, ... #<FileInfo:0x0N>] 进行【分组】
        @group_app_files = parse_app_files.group_by { |e|
          e.type
        }
        # pp @group_app_files

        @group_app_files
      end

      def category_app_files
        return @category_app_files if @category_app_files

        #
        # 解析生成 FileCategory(文件类型)/FileInfo(文件) 结构
        # [
        #   #<FileCategory:0x01>, @name="分类1", @file_infos=[#<FileInfo:0x01>, #<FileInfo:0x02>, ... #<FileInfo:0x0N>],
        #   #<FileCategory:0x01>, @name="分类2", @file_infos=[#<FileInfo:0x01>, #<FileInfo:0x02>, ... #<FileInfo:0x0N>],
        #   ...
        #   #<FileCategory:0x01>, @name="分类3", @file_infos=[#<FileInfo:0x01>, #<FileInfo:0x02>, ... #<FileInfo:0x0N>],
        # ]
        @category_app_files = group_app_files.map { |k ,v|
          FileCategory.categories(k, v, executable: @info.executable)
        }.compact.flatten
        # pp file_categories.count
        # pp file_categories

        @category_app_files
      end

      def flatten_unknown_category
        return @unknown_category if @unknown_category

        #
        # 从 grouped 之后的 文件类型, 移除出来的 重复的 name == 'Unknown' 的 UNKNOWN FileCategory
        categories_unknowned = category_app_files.select { |c|
          c.name == FileCategory::UNKNOWN
        }
        # pp categories_unknowned

        #
        # 平铺 UNKNOWN FileCategory 中的, 多个 FileCategory/FileInfo数组
        unknown_files_infos = []
        categories_unknowned.each_with_object(unknown_files_infos) { |e, mem|
          mem.concat(e.file_infos).compact.flatten
        }
        unknown_files_infos.uniq! { |e| e.name }

        #
        # 重新创建 FileCategory, 并归属包含的 FileInfo
        @unknown_category = FileCategory.categories(FileCategory::UNKNOWN_FILES, unknown_files_infos)
        @unknown_category
      end

      def categories
        return @categories if @categories

        #
        # 去除 file categories 中, name == 'Unknown' 重复的 Unknown FileCategory
        categories_rejected = category_app_files.reject { |c|
          c.name == FileCategory::UNKNOWN
        }
        # pp categories_rejected.count

        #
        # 再追加 平铺(flatten) 之后的 UNKNOWN FileCategory
        categories_rejected.push(flatten_unknown_category)

        #
        # sort FileCategory
        categories_sorted = categories_rejected.sort { |a, b|
          b.size <=> a.size
        }

        # sort FileCategory.files
        @categories = categories_sorted.map { |e|
          e.file_infos = e.file_infos.sort { |a, b|
            b.size <=> a.size
          }
          e
        }
        # pp @categories.count
        # pp @categories

        @categories
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
