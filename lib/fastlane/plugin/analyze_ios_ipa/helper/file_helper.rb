require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Helper
    class FileHelper
      def self.file_join(files)
        # File.join('DKNightVersion', 'Pod', 'Classes', 'UIKit') => DKNightVersion/Pod/Classes/UIKit
        File.join(files)
      end

      def self.file_size(file_path, log = false)
        total = 0
        return 0 unless File.exist?(file_path)

        base = File.basename(file_path)
        return 0 if ['.',  '..'].include?(base)

        dir = File.dirname(file_path)
        file_path = file_join([dir, base])

        if File.directory?(file_path)
          printf("Dir: %s\n", file_path) if log
          Dir.foreach(file_path) { |file_name|
            total += file_size(file_join([file_path, file_name]), log)
          }
        else
          size = File.stat(file_path).size
          printf("File: %s - %d byte\n", file_path, size) if log
          total += size
        end

        total
      end

      def self.format_size(bytes, k = 1024)
        return '0 B' unless bytes
        return '0 B' if bytes.zero?

        suffix = %w[B KB MB GB TB PB EB ZB YB]
        i = (Math.log(bytes) / Math.log(k)).floor
        base = (k ** i).to_f
        num = (bytes / base).round(2)
        "#{num} " + suffix[i]
      end

      def self.glob_files(expr, dir)
        Dir.glob(File.expand_path(expr, dir))
      end

      def self.mv_file(src, dest)
        FileUtils.mv(src, dest)
      end

      def self.cp_file(src, dest)
        FileUtils.cp_r(src, dest)
      end

      def self.unzip_file(src, dest)
        FileUtils.mkdir_p(dest) unless Dir.exist?(dest)
        Zip::File.open(src) do |zip_file|
          zip_file.each do |f|
            fpath = File.join(dest, f.name)
            zip_file.extract(f, fpath) unless File.exist?(fpath)
          end
        end
      end

      def self.unzip_ipa(ipa, output)
        return nil unless ipa
        return nil if ipa.empty?
        return nil unless File.exist?(ipa)

        ## create output dir if need ?
        FileUtils.rm_rf(output)
        FileUtils.mkdir_p(output)

        ## xx.ipa => xx.zip
        cp_dest = File.expand_path('app.zip', output)
        cp_file(ipa, cp_dest)

        ## xx.zip => Payload/
        unzip_file(cp_dest, output)

        File.expand_path('Payload', output)
      end
    end
  end
end
