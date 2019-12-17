require 'fastlane_core/ui/ui'
module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    require 'cfpropertylist'
    class InfoPlist
      def initialize(plist)
        @plist = plist
      end

      def prase
        return @info if @info
        @info = CFPropertyList.native_types(CFPropertyList::List.new(file: @plist).value)
        @info
      end

      # def
      #   prase['']
      # end

      def executable
        prase['CFBundleExecutable']
      end

      def device_capabilities
        prase['UIRequiredDeviceCapabilities']
      end

      def app_type
        prase['ZHAppBuildType']
      end

      def identifier
        prase['CFBundleIdentifier']
      end

      def bundle_name
        prase['CFBundleName']
      end

      def display_name
        prase['CFBundleDisplayName']
      end

      def version
        prase['CFBundleVersion']
      end

      def short_version
        prase['CFBundleShortVersionString']
      end
    end
  end
end
