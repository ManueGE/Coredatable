# Change Log

## Betas 

### 0.1.0
- `NSManagedObject` subclasses doesn't require to be final to adopt `Coredatable`. 
- Method `func initialize(from container: CoreDataKeyedDecodingContainer<Self>)` replaced to `func initialize(from decoder: Decoder) throws` 
- Method `static func prepare(_ container: CoreDataKeyedDecodingContainer<Self>) throws -> CoreDataKeyedDecodingContainer<Self>` replaced to ` static func container(for decoder: Decoder) throws -> AnyCoreDataKeyedDecodingContainer` 

### 0.0.1
- Initial version
