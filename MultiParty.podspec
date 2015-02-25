Pod::Spec.new do |s|
  s.name             = "MultiParty"
  s.version          = "0.1.2"
  s.summary          = "Putting some fun into MultipeerConnectivity"
  s.description      = <<-DESC
                       A wrapper for Apple's MultipeerConnectivity framework that
                       makes it easier to handle common uses, such as peer-to-peer
                       chat. See https://github.com/dustMason/JSMultiParty for more.
                       DESC
  s.homepage         = "https://github.com/dustMason/JSMultiParty"
  s.license          = 'MIT'
  s.author           = { "Jordan Sitkin" => "jordan@fiftyfootfoghorn.com" }
  s.source           = { :git => "https://github.com/dustMason/JSMultiParty.git", :tag => s.version.to_s }
  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.source_files = 'JSMultiParty.swift'
  s.framework = 'MultipeerConnectivity'
end
