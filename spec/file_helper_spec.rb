describe Fastlane::Helper::FileHelper do
  describe '#run' do
    it 'unzip' do
      ipa     = '/Users/xiongzenghui/Downloads/app.ipa'
      output  = '/Users/xiongzenghui/Downloads/output'
      payload = Fastlane::Helper::FileHelper.unzip_ipa(ipa, output)
      puts "payload: #{payload}"
    end
  end
end
