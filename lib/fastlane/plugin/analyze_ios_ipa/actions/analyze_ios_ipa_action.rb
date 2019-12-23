require 'fastlane/action'
require_relative '../helper/config'
require_relative '../helper/file_helper'
require_relative '../helper/app'

module Fastlane
  module Actions
    module SharedValues
      AnalyzeIosIpaActionResultHash = :AnalyzeIosIpaActionResultHash
      AnalyzeIosIpaActionResultJSON = :AnalyzeIosIpaActionResultJSON
    end

  #  Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::GITLAB_AUTO_MERGE_WEB_URL]

    class AnalyzeIosIpaAction < Action
      def self.run(params)
        ipa_path = params[:ipa_path]
        app_path = params[:app_path]
        app_name = params[:app_name]
        group    = params[:group] || true
        valid_params(ipa_path, app_path)

        UI.important("❗️[analyze_ios_ipa_action:run] ipa: #{ipa_path}")
        UI.important("❗️[analyze_ios_ipa_action:run] app: #{app_path}")
        UI.important("❗️[analyze_ios_ipa_action:run] app.name: #{app_name}")
        UI.important("❗️[analyze_ios_ipa_action:run] group: #{group}")

        ret = if ipa_path
          analyze_ipa(group)
        elsif app_path
          analyze_app(group)
        else
          false
        end
        return false unless ret

        Actions.lane_context[Actions::SharedValues::AnalyzeIosIpaActionResultHash] = generate_hash
        Actions.lane_context[Actions::SharedValues::AnalyzeIosIpaActionResultJSON] = generate_json
        true
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
      end

      def self.analyze_ipa(group)
        ipa_path = Fastlane::Helper::Config.instance.ipa_path
        UI.important "❗️[analyze_ios_ipa_action:analyze_ipa] ipa_path: #{ipa_path}"

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
        app_paths = Fastlane::Helper::FileHelper.glob_files('*.app', payload)
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
        analyze_app(group)
        true
      end

      def self.analyze_app(group)
        app_path   = Fastlane::Helper::Config.instance.app_path
        UI.important "❗️[analyze_ios_ipa_action:analyze_app] app_path: #{app_path}"

        return false unless app_path
        return false if app_path.empty?
        return false unless File.exist?(app_path)

        # 解析 xx.app
        app = Fastlane::Helper::App.new(app_path, group: group)
        Fastlane::Helper::Config.instance.app = app
        true
      end

      def self.generate_json
        JSON.generate(generate_hash)
      end

      def self.generate_hash
        {
          ipa: (Fastlane::Helper::Config.instance.ipa.generate_hash if Fastlane::Helper::Config.instance.ipa),
          app: (Fastlane::Helper::Config.instance.app.generate_hash if Fastlane::Helper::Config.instance.app)
        }.compact
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
            description: 'app executable file name',
            type: String,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :group,
            description: 'is group files in xx.app ?',
            optional: true,
            default_value: true,
            is_string: false
          )
        ]
      end

      def self.is_supported?(platform)
        :ios == platform
      end
    end
  end
end
