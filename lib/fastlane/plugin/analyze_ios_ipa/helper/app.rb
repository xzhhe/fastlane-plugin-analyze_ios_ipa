require 'fastlane_core/ui/ui'
module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    require_relative 'info_plist'
    require_relative 'ipa'
    require_relative 'file_info'
    require_relative 'file_category'

    class App
      ATTRS = [:size, :formar_size, :info, :files, :file_infos, :executable, :bundles, :frameworks, :categories]
      attr_accessor(*ATTRS)

      def to_hash
        {
          size: @size,
          formar_size: @formar_size,
          info: {
            executable: @info.executable,
            device_capabilities: @info.device_capabilities,
            # app_type: @info.app_type, #=> 只有自己项目使用
            identifier: @info.identifier,
            display_name: @info.display_name,
            version: @info.version,
            short_version: @info.short_version
          },
          categories: @categories.map(&:to_hash)
        }
      end

      def initialize(app_path)
        @app_path = app_path

        return nil unless app_path
        return nil if app_path.empty?
        return nil unless File.exist?(app_path)

        # size
        @size        = FileHelper.file_size(app_path)
        @formar_size = FileHelper.format_size(@size)

        # info.plist
        info_plist_path = File.expand_path('Info.plist', app_path)
        @info = InfoPlist.new(info_plist_path)

        # files
        parse_files
      end

      def parse_files
        return @categories if @categories

        @files = Dir.glob(File.expand_path('*', @app_path))
        # puts @files

        @file_infos = files.map {|f|
          FileInfo.new(f)
        }
        # pp @file_infos

        @goruped_file_infos = @file_infos.group_by { |e|
          e.type
        }
        # pp @goruped_file_infos

        categories = []
        unknown_fc = FileCategory.new
        unknown_fc.name = 'Unknown'
        @goruped_file_infos.each { |k, v|
          if :FileInfoUnknownDir == k
            v.each { |e|
              # pp e
              if e.name == 'PlugIns'
                # PlugIns/
                ffc = FileCategory.new
                ffc.name = 'PlugIns'
                ffc.merge(Dir.glob(File.expand_path('*', e.path)).map { |f|
                  FileInfo.new(f)
                })
                ffc.finish
                categories << ffc
              elsif e.name == 'Frameworks'
                # Frameworks/
                ffc = FileCategory.new
                ffc.name = 'Frameworks'
                ffc.merge(Dir.glob(File.expand_path('*', e.path)).map { |f|
                  FileInfo.new(f)
                })
                ffc.finish
                categories << ffc
              else
                unknown_fc.push(e)
              end
            }
          elsif :FileInfoUnknownFile == k
            v.map { |e|
              if e.name == @info.executable
                ffc = FileCategory.new
                ffc.name = 'executable'
                ffc.push(FileInfo.new(e.path))
                ffc.finish
                categories << ffc
              else
                unknown_fc.push(e)
              end
            }
          else
            ffc = FileCategory.new
            ffc.name = k
            ffc.merge(v)
            ffc.finish
            categories << ffc
          end
        }
        unknown_fc.finish
        categories << unknown_fc

        categories.sort! { |left, right|
          right.size <=> left.size
        }

        @categories = categories
        # pp categories
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
