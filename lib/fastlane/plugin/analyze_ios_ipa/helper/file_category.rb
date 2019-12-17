require 'fastlane_core/ui/ui'
module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    class FileCategory
      attr_accessor :name, :file_infos, :size, :formar_size

      def to_hash
        {
          name: @name,
          size: @size,
          formar_size: @formar_size,
          files: @file_infos.map(&:to_hash)
        }
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
