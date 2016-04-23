#
# Be sure to run `pod lib lint SQLiteModel.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SQLiteModel"
  s.version          = "0.1.4"
  s.summary          = "The easiest way to persist data in Swift"

  s.description      = <<-DESC
        SQLiteModel is a developer friendly SQLite ORM written in swift, wrapped over SQLite.swift
                       DESC

  s.homepage         = "https://github.com/jhurray/SQLiteModel"
  s.license          = 'MIT'
  s.author           = { "Jeff Hurray" => "jhurray@umich.edu" }
  s.source           = { :git => "https://github.com/jhurray/SQLiteModel.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/JeffHurray'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'SQLiteModel/*.{h,swift}'
  s.libraries = 'sqlite3'
  s.dependency 'SQLite.swift', '~> 0.9.0'
end
