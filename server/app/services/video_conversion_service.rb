class VideoConversionService < ApplicationService
  AUDIO_OPTIONS = %w[-vn -ar 44100 -ac 2 -b:a 128k].freeze

  def initialize(video)
    @video = video
    @file_path = Rails.root.join('storage', 'videos', @video.storage_key.to_s)
    @audio_filename = "#{@video.id}_#{SecureRandom.hex(8)}_audio.mp3"
    @audio_output_path = Rails.root.join('storage', 'audios', @audio_filename)
  end

  def call
    puts "CHECKPOINTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT CONVERSION SERVICE"

    return false unless prepare_conversion
    return false unless convert_to_audio

    true
  rescue VideoProcessingError::Base => e
    log_error("Video processing error", e)
    @video.update(status: :failed)
    false
  rescue => e
    log_error("Unexpected error during conversion", e)
    @video.update(status: :failed)
    false
  end

  private

  def prepare_conversion
    puts "CHECKPOINTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT CONVERSION SERVICE"
    FileUtils.mkdir_p(@audio_output_path.dirname)
    @video.update!(status: :processing)

    unless File.exist?(@file_path)
      raise VideoProcessingError::StorageError, "Video file not found: #{@file_path}"
    end

    movie = FFMPEG::Movie.new(@file_path.to_s)
    unless movie.valid?
      raise VideoProcessingError::ValidationError, "Invalid video file"
    end

    @movie = movie
    true
  end

  def convert_to_audio
    audio = @movie.transcode(@audio_output_path.to_s, AUDIO_OPTIONS)

    if audio && File.exist?(@audio_output_path) && audio.valid?
      @video.update!(
        status: :audio_extracted,
        audio_storage_key: @audio_filename,
        duration_seconds: @movie.duration.to_i
      )
      true
    else
      raise VideoProcessingError::ConversionError, "Failed to create valid audio file"
    end
  end

  def corrupted?
    VideoValidationService.call(@video)
  end
end