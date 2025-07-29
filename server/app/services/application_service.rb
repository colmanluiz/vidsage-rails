class ApplicationService
  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private

  def log_error(message, error = nil)
    error_message = error ? "#{message}: #{error.class} - #{error.message}" : message
    Rails.logger.error(error_message)
    error_message
  end
end