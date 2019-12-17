require 'fastlane_core/ui/ui'
module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    class Ipa
      ATTRS = [:size, :formar_size]
      attr_accessor(*ATTRS)

      def initialize(ipa_path)
        return nil unless ipa_path
        return nil if ipa_path.empty?
        return nil unless File.exist?(ipa_path)

        # size
        @size        = FileHelper.file_size(ipa_path)
        @formar_size = FileHelper.format_size(@size)
      end

      def to_hash
        {
        }
      end
    end
  end
end
