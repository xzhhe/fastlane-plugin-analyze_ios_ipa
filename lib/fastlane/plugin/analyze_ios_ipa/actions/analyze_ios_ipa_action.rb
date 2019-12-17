require 'fastlane/action'
require_relative '../helper/config'
require_relative '../helper/file_helper'
require_relative '../helper/app'

module Fastlane
  module Actions
    class AnalyzeIosIpaAction < Action
      def self.run(params)
        ipa_path = params[:ipa_path]
        app_name = params[:app_name]
        app_path = params[:app_path]

        valid_params(ipa_path, app_path)
        analyze_ipa if ipa_path
        # analyze_app if app_path
        generate_result
      end

      def self.valid_params(ipa_path, app_path)
        UI.user_error!("❌ ipa_path 与 app_path 至少传入一个!") if !ipa_path && !app_path

        if ipa_path
          UI.user_error!("❌ #{ipa_path} 文件不存在!") unless File.exist?(ipa_path)
        end

        if app_path
          UI.user_error!("❌ #{app_path} 文件不存在!") unless File.exist?(app_path)
        end

        Fastlane::Helper::Config.instance.ipa_path = ipa_path
        Fastlane::Helper::Config.instance.app_path = app_path
        # UI.important("[valid_params] ipa_path: #{Fastlane::Helper::Config.ipa_path}")
        # UI.important("[valid_params] app_path: #{Fastlane::Helper::Config.app_path}")
      end

      def self.analyze_ipa
        ipa_path = Fastlane::Helper::Config.instance.ipa_path
        UI.important "❗️[analyze_ipa] ipa_path: #{ipa_path}"

        return false unless ipa_path
        return false if ipa_path.empty?
        return false unless File.exist?(ipa_path)

        # 解析 xx.ipa
        ipa = Fastlane::Helper::Ipa.new(ipa_path)
        Fastlane::Helper::Config.instance.ipa = ipa

        # xx.ipa => xx.app
        output = File.expand_path('output', File.dirname(ipa_path))
        payload = Fastlane::Helper::FileHelper.unzip_ipa(ipa_path, output)
        UI.success "✅ unzip ipa to: #{payload}"

        # find xx.app
        app_path = nil
        app_paths = Dir.glob(File.expand_path('*.app', payload))
        if app_paths.empty?
          UI.user_error!("❌ app_name not give") unless app_name

          app_path = File.expand_path("#{app_name}.app", payload)
          UI.user_error!("❌ #{app_path} not exist") unless File.exist?(app_path)
        else
          app_path = app_paths.first
        end
        # UI.important("❗️[ipa_unzip_to_app_call_analyze] app_path: #{app_path}")
        Fastlane::Helper::Config.instance.app_path = app_path

        # 解析 xx.app
        analyze_app
      end

      def self.analyze_app
        app_path   = Fastlane::Helper::Config.instance.app_path
        UI.important "❗️[analyze_app] app_path: #{app_path}"

        return false unless app_path
        return false if app_path.empty?
        return false unless File.exist?(app_path)

        # 解析 xx.app
        app = Fastlane::Helper::App.new(app_path)
        puts app.generate_json

        # save app
        Fastlane::Helper::Config.instance.app = app
      end

      def self.generate_result
        # UI.important("🚗" * 50)
        # pp Fastlane::Helper::Config.instance.ipa
        # UI.important("🚙" * 50)
        # pp Fastlane::Helper::Config.instance.app
      end

      def self.description
        'analysis iOS app/ipa multiple data. eg: 1) ipa basic info 2) Size occupied by each component = code + resource'
      end

      def self.authors
        ["xiongzenghui"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        'analysis iOS app/ipa multiple data. eg: 1) ipa basic info 2) Size occupied by each component = code + resource'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :ipa_path,
            description: 'ipa file path',
            type: String,
            optional: true,
            conflicting_options: [:app_path]
          ),
          FastlaneCore::ConfigItem.new(
            key: :app_path,
            description: 'app file path',
            type: String,
            optional: true,
            conflicting_options: [:ipa_path]
          ),
          FastlaneCore::ConfigItem.new(
            key: :app_name,
            description: 'app file path',
            type: String,
            optional: true
          )
        ]
      end

      def self.is_supported?(platform)
        :ios == platform
      end
    end
  end
end
