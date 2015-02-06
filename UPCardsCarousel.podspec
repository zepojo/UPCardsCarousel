Pod::Spec.new do |s|
  s.name             = "UPCardsCarousel"
  s.version          = "1.0.2"
  s.summary          = "A cards based carousel for iOS."
  s.description      = "UPCardsCarousel is a carousel with a fancy cards based UI for iOS."
  s.homepage         = "https://github.com/ink-spot/UPCardsCarousel"
  # s.screenshots    = "https://raw.githubusercontent.com/ink-spot/UPCardsCarousel/master/images/demo.gif"
  s.license          = 'MIT'
  s.author           = { "Paul Ulric" => "ink.and.spot@gmail.com" }
  s.source           = { :git => "https://github.com/ink-spot/UPCardsCarousel.git", :tag => s.version.to_s }
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'UPCardsCarousel'
end
