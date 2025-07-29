FactoryBot.define do
  factory :video do
    filename { "MyString" }
    original_size { "" }
    duration_seconds { 1 }
    status { 1 }
    storage_key { "MyString" }
    audio_storage_key { "MyString" }
  end
end
