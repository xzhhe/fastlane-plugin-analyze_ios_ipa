describe Fastlane::Actions::AnalyzeIosIpaAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The analyze_ios_ipa plugin is working!")

      Fastlane::Actions::AnalyzeIosIpaAction.run(nil)
    end
  end
end
