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
      # Read more bytes to properly identify file types
      header = file.read(12)
      return false if header.nil? || header.length < 8
      
      puts "File header bytes: #{header[0..11].unpack('C*').map { |b| format('%02X', b) }.join(' ')}"
      
      # Check for video file signatures
      # MP4/MOV: Look for 'ftyp' at offset 4
      return true if header[4..7] == "ftyp"
      
      # AVI: Starts with 'RIFF' and has 'AVI ' at offset 8
      return true if header[0..3] == "RIFF" && header[8..11] == "AVI "
      
      # MKV/WebM: Starts with EBML signature
      return true if header[0..3] == "\x1A\x45\xDF\xA3"
      
      # QuickTime: Alternative signature
      return true if header[4..7] == "mdat" || header[4..7] == "wide"
      
      # 3GP files (mobile video)
      return true if header[4..6] == "3gp" || header[4..6] == "3g2"
      
      puts "No valid video signature found"
      false
    end
  rescue => e
    log_error("Error reading file headers", e)
    false
  end

  def valid_ffprobe?
    command = "ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 #{Shellwords.escape(@file_path)}"
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