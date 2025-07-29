class VideoProcessingJob < ApplicationJob
  queue_as :video_processing
  retry_on VideoProcessingError::Base, wait: :exponentially_longer, attempts: 3

  def perform(video_id)
    video = Video.find(video_id)

    if VideoValidationService.call(video)
      puts "CHECKPOINTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT VALIDATION SERVICE"
      VideoConversionService.call(video)
    else
      puts "CHECKPOINTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT else"
      video.update(status: :failed)
    end
  rescue ActiveRecord::RecordNotFound => e
    log_error("Video not found", e)
  end

  private

  def log_error(message, error)
    Rails.logger.error("[VideoProcessingJob] #{message}: #{error.class} - #{error.message}")
  end
end