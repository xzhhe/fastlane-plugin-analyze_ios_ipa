require 'fastlane_core/ui/ui'
module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    require_relative 'info_plist'

    #
    # 文件
    #
    class FileInfo
      FileInfoUnknownFile = :FileInfoUnknownFile
      FileInfoUnknownDir  = :FileInfoUnknownDir
      FileInfoUnknown     = :FileInfoUnknown

      attr_accessor :name, :path, :size, :formar_size, :type

      def to_hash
        {
          name:        @name,
          size:        @size,
          formar_size: @formar_size,
          path:        @path,
          type:        @type
        }
      end

      def initialize(file_path)
        @name = File.basename(file_path)
        @path = file_path
        @size = FileHelper.file_size(file_path)
        @formar_size = FileHelper.format_size(@size)

        names = @name.split('.')
        @type = if names.count > 1
          names.last
        else
          if File.stat(file_path).file?
            FileInfoUnknownFile
          elsif File.directory?(".")
            FileInfoUnknownDir
          else
            FileInfoUnknown
          end
        end
      end

      def unknown_file?
        @type == FileInfoUnknownFile
      end

      def unknown_dir?
        @type == FileInfoUnknownDir
      end

      def bundle?
        @type == 'bundle'
      end

      def framework?
        @name == 'framework'
      end

      def dylib?
        @name == 'dylib'
      end

      def strings?
        @type == 'strings'
      end

      def plist?
        @type == 'plist'
      end
    end
  end
end
