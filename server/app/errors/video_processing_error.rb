module VideoProcessingError
  class Base < StandardError; end
  class ValidationError < Base; end
  class ConversionError < Base; end
  class StorageError < Base; end
  class FFprobeError < ValidationError; end
end