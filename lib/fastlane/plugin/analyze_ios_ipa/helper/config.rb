require 'fastlane_core/ui/ui'
module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    class Config
      include Singleton
      ATTRS = [:ipa_path, :app_path, :ipa, :app]
      attr_accessor(*ATTRS)

      def self.ipa_path
        self.instance.ipa_path
      end

      def self.app_path
        self.instance.app_path
      end
    end
  end
end
