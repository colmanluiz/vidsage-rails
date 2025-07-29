class Video < ApplicationRecord
  # Status tracking for video processing pipeline
  enum :status, {
    uploaded: 0,
    processing: 1,
    audio_extracted: 2,
    transcribing: 3,
    transcribed: 4,
    vectorizing: 5,
    ready: 6,
    failed: 7,
    corrupted: 8
  }

  # Validations
  validates :filename, presence: true
  validates :status, presence: true
  validates :original_size, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 50.megabytes }

  # Future associations (we'll create these models later)
  # has_one :transcription, dependent: :destroy
  # has_many :video_queries, dependent: :destroy

  # Scopes for common queries
  scope :ready_for_querying, -> { where(status: :ready) }
  scope :processing_videos, -> { where(status: [:processing, :audio_extracted, :transcribing, :transcribed, :vectorizing]) }

  # Instance methods
  def processing?
    %w[processing audio_extracted transcribing transcribed vectorizing].include?(status)
  end

  def failed?
    status == 'failed'
  end

  def ready_for_queries?
    status == 'ready'
  end

  def duration_formatted
    return "Unknown" unless duration_seconds.present?
    
    hours = duration_seconds / 3600
    minutes = (duration_seconds % 3600) / 60
    seconds = duration_seconds % 60
    
    if hours > 0
      "#{hours}:#{format('%02d', minutes)}:#{format('%02d', seconds)}"
    else
      "#{minutes}:#{format('%02d', seconds)}"
    end

    # TODO: test it later
    # Rails provides distance_of_time_in_words, but it's more verbose (e.g., "about 1 hour")
    # For a compact HH:MM:SS or MM:SS, we can use Time.at and strftime:
    # if duration_seconds
    #   t = Time.at(duration_seconds).utc
    #   duration_seconds >= 3600 ? t.strftime("%H:%M:%S") : t.strftime("%M:%S")
    # else
    #   "Unknown"
    # end
  end

  def file_size_formatted
    return "Unknown" unless original_size.present?
    ActionController::Base.helpers.number_to_human_size(original_size)
  end
end
