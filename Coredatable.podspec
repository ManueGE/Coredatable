Pod::Spec.new do |spec|

  spec.name         = "Coredatable"
  spec.version      = "0.0.1"
  spec.summary      = "Easy Codable conformance in NSManagedObject subclasses."
  spec.description  = <<-DESC
  Adding `Decodable` and `Encodable` conformance to `NSManagedObject` subclasses is usually very tricky. 
  Coredatable simplifies this process using equivalent protocols called `CoreDataDecodable`, `CoreDataEncodable` and `CoreDataCodable`.
                   DESC
  spec.homepage     = "https://github.com/ManueGE/Coredatable/"
  spec.license      = "MIT"


  spec.author    = "Manuel García-Estañ"
  spec.social_media_url   = "http://twitter.com/ManueGE"

  spec.platform     = :ios, "10.0"
  spec.source       = { :git => "https://github.com/ManueGE/Coredatable.git", :tag => "#{spec.version}" }

  spec.requires_arc = true
  spec.framework = "UIKit"
  spec.framework = "CoreData"

  spec.source_files = "Coredatable/*.{swift,h,m}"
end
