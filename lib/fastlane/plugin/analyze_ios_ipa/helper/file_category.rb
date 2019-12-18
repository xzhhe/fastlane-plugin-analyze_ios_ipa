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
      attr_accessor :name, :file_infos, :size, :formar_size

      def to_hash
        {
          name:        @name,
          size:        @size,
          formar_size: @formar_size,
          files:       @file_infos.map(&:to_hash)
        }
      end

      def self.categories(type, infos, options = {})
        executable = options[:executable]

        block = {
          FileInfoUnknownDir: lambda do |infos|
            # - 1) PlugIns
            # - 2) Frameworks

            infos.map { |e|
              fc = FileCategory.new
              if e.name == 'PlugIns'
                fc.name = 'PlugIns'
                fc.merge(FileHelper.glob_files('*', e.path).map { |f|
                  FileInfo.new(f)
                })
              elsif e.name == 'Frameworks'
                fc = FileCategory.new
                fc.name = 'Frameworks'
                fc.merge(FileHelper.glob_files('*', e.path).map { |f|
                  FileInfo.new(f)
                })
              else
                fc.name = 'Unknown'
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
              if e.name == executable
                fc.name = 'executable'
                fc.push(FileInfo.new(e.path))
              else
                fc.name = 'Unknown'
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
        @formar_size = FileHelper.format_size(@size)
      end
    end
  end
end
