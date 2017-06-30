#
# Be sure to run `pod lib lint MMDownloadManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MMDownloadManager'
  s.version          = '0.0.1'
  s.summary          = '轻量级 Swift 版下载管理器.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
轻量级 Swift 版下载管理器。支持多任务断点续传，自定义存储路径，可设置最大并发下载数量。
                       DESC

  s.homepage         = 'https://github.com/zhangyinglong/MMDownloadManager'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zhangyinglong' => 'zyl04401@gmail.com' }
  s.source           = { :git => 'https://github.com/zhangyinglong/MMDownloadManager.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.module_name  = 'MMDownloadManager'
  s.requires_arc          = true
  s.ios.deployment_target = '8.0'

  s.source_files = 'MMDownloadManager/**/*.swift'
end
