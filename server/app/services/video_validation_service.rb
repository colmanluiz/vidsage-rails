class VideoValidationService < ApplicationService
  ALLOWED_MIME_TYPES = %w[
    video/mp4
    video/avi
    video/quicktime
    video/x-msvideo
    video/x-matroska
  ].freeze

  def initialize(video)
    @video = video
    @file_path = Rails.root.join('storage', 'videos', @video.storage_key.to_s)
  end

  def call
    puts "CHECKPOINTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT VALIDATION SERVICE"
    return false unless basic_validations
    return false unless valid_file_headers?
    return false unless valid_ffprobe?
    
    true
  rescue => e
    log_error("Unexpected error during video validation", e)
    false
  end

  private

  def basic_validations
    puts "CHECKPOINTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT VALIDATION SERVICE"
    return false unless @video.storage_key.present?
    return false unless File.exist?(@file_path)
    return false unless valid_mime_type?
    true
  end

  def valid_mime_type?
    mime_type = Marcel::MimeType.for(Pathname.new(@file_path))
    ALLOWED_MIME_TYPES.include?(mime_type)
  end

  def valid_file_headers?
    File.open(@file_path, 'rb') do |file|
      magic = file.read(4)
      # Check for common video file signatures
      return true if magic.start_with?("\x00\x00\x00\x18ftypmp42") # MP4
      return true if magic.start_with?("RIFF") # AVI
      return true if magic.start_with?("\x00\x00\x00\x14ftypqt") # MOV
      return true if magic.start_with?("\x1A\x45\xDF\xA3") # MKV
    end
    false
  rescue => e
    log_error("Error reading file headers", e)
    false
  end

  def valid_ffprobe?
    command = "ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 #{Shellwords.escape(@file_path)}"
    puts "====================================================="
    puts command
    stdout, stderr, status = Open3.capture3(command)

    if status.success? && stderr.empty? && stdout.present?
      @video.update(duration_seconds: stdout.to_f)
      true
    else
      log_error("FFprobe validation failed: #{stderr}")
      false
    end
  rescue Errno::ENOENT => e
    log_error("FFprobe not found", e)
    false
  end
end