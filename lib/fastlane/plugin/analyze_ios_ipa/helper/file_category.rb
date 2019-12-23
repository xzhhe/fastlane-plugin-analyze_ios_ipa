require 'fastlane_core/ui/ui'
module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    require_relative 'file_info'
    require_relative 'file_helper'

    #
    # 文件类型
    #
    class FileCategory
      attr_accessor :name, :file_infos, :size, :format_size

      PLUGINS       = 'PlugIns'
      FRAMEWORKS    = 'Frameworks'
      UNKNOWN       = 'Unknown'
      UNKNOWN_FILES = 'UnknownFiles'
      EXECUTABLE    = 'executable'

      def to_hash
        {
          name:        @name,
          size:        @size,
          format_size: @format_size,
          files:       @file_infos.map(&:to_hash)
        }
      end

      #
      # @param type:  文件类型: FileInfo::FileInfoUnknownDir, FileInfo::FileInfoUnknownFile, FileInfo::FileInfoUnknown
      # @param infos: 文件数组: [#<FileInfo:0x01>, #<FileInfo:0x02>, ... #<FileInfo:0x0N>]
      #
      def self.categories(type, infos, options = {})
        executable_name = options[:executable]

        block = {
          FileInfoUnknownDir: lambda do |infos|
            # 主要是将如下两个目录, 继续递归遍历解析
            # - 1) PlugIns 类型
            # - 2) Frameworks 类型
            # - 3) Unknown 类型

            infos.map { |e|
              fc = FileCategory.new
              if e.name == PLUGINS
                fc.name = PLUGINS
                fc.merge(FileHelper.glob_files('*', e.path).map { |f|
                  FileInfo.new(f)
                })
              elsif e.name == FRAMEWORKS
                fc = FileCategory.new
                fc.name = FRAMEWORKS
                fc.merge(FileHelper.glob_files('*', e.path).map { |f|
                  FileInfo.new(f)
                })
              else
                fc.name = UNKNOWN
                fc.push(e)
              end
              fc.finish
              fc
            }
          end,
          FileInfoUnknownFile: lambda do |infos|
            # - 1) executable

            infos.map { |e|
              fc = FileCategory.new
              if e.name == executable_name
                fc.name = EXECUTABLE
                fc.push(FileInfo.new(e.path))
              else
                fc.name = UNKNOWN
                fc.push(e)
              end
              fc.finish
              fc
            }
          end
        }[type]

        if block
          # puts "[1] type: #{type} -- #{infos.count}"
          block.call(infos)
        else
          # puts "[2] type: #{type} -- #{infos.count}"

          #
          # Plugins/、Frameworks/、app mach-o , 三者之外的其他类型的文件

          fc = FileCategory.new
          fc.name = type
          fc.merge(infos)
          fc.finish
          fc
        end
      end

      def initialize
        @file_infos = []
      end

      def push(info)
        @file_infos << info
      end

      def merge(infos)
        @file_infos += infos
      end

      def finish
        @size = @file_infos.map(&:size).inject(0, :+)
        @format_size = FileHelper.format_size(@size)
      end
    end
  end
end
