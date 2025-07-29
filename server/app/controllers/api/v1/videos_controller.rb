class Api::V1::VideosController < Api::V1::BaseController
  before_action :find_video, only: [:show, :status, :query]

  VIDEO_STORAGE_PATH = Rails.root.join('storage', 'videos').freeze

  def index
    @videos = Video.order(created_at: :desc)
    render_success(@videos.map { |video| video_summary(video) })
  end

  def show
    render_success(video_details(@video))
  end

  def create
    unless params[:video_file].present?
      return render_error('Video file is required')
    end

    video_file = params[:video_file]

    @video = Video.new(
      filename: video_file.original_filename,
      original_size: video_file.size,
      status: :uploaded
    )

    if @video.save
      begin
        store_video_file(@video, video_file)
        VideoProcessingJob.perform_later(@video.id)
        render_success(video_details(@video), 'Video uploaded successfully')
      rescue => e
        @video.update(status: :failed)
        render_error("Failed to process video: #{e.message}")
      end
    else
      render_error('Failed to create video record', :unprocessable_entity, @video.errors)
    end
  end

  def status
    render_success({
                     id: @video.id,
                     status: @video.status,
                     processing: @video.processing?,
                     ready_for_queries: @video.ready_for_queries?
                   })
  end

  def query
    unless @video.ready_for_queries?
      return render_error("Video is not ready for queries yet. Current status: #{@video.status}")
    end

    question = params[:question]
    unless question.present?
      return render_error('Question is required')
    end

    # TODO: Implement RAG query logic
    # For now, return a placeholder response
    render_success({
                     question: question,
                     answer: "RAG functionality coming soon! Your question about the video: '#{question}'",
                     video_id: @video.id
                   })
  end

  private

  def find_video
    @video = Video.find_by(id: params[:id])
    render_not_found('Video not found') unless @video
  end

  def video_summary(video)
    {
      id: video.id,
      filename: video.filename,
      status: video.status,
      duration: video.duration_formatted,
      file_size: video.file_size_formatted,
      created_at: video.created_at,
      ready_for_queries: video.ready_for_queries?
    }
  end

  # The `merge` method here takes the hash returned by `video_summary(video)` and combines it
  # with another hash containing :storage_key, :audio_storage_key, and :processing.
  # If any keys overlap, the values from the second hash will overwrite those from the first.
  def video_details(video)
    # Combine the summary hash with additional details
    video_summary(video).merge({
      storage_key: video.storage_key,
      audio_storage_key: video.audio_storage_key,
      processing: video.processing?
    })
  end

  # Store uploaded video file using centralized storage path
  def store_video_file(video, file)
    FileUtils.mkdir_p(VIDEO_STORAGE_PATH)

    storage_key = "#{video.id}_#{SecureRandom.hex(8)}_#{file.original_filename}"
    file_path = VIDEO_STORAGE_PATH.join(storage_key)

    File.open(file_path, 'wb') do |f|
      f.write(file.read)
    end

    video.update!(storage_key: storage_key)
  end
end