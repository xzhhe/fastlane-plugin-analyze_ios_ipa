describe Fastlane::Helper::AnalyzeIpaHelper do
  describe '#run' do
    it 'run' do
      ipa     = '/Users/xiongzenghui/Downloads/app.ipa'
      puts Fastlane::Helper::AnalyzeIpaHelper.ipa_size(ipa)
      puts Fastlane::Helper::AnalyzeIpaHelper.format_ipa_size(ipa)
    end
  end
end
