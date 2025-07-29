class CreateVideos < ActiveRecord::Migration[7.2]
  def change
    create_table :videos do |t|
      t.string :filename, null: false
      t.bigint :original_size
      t.integer :duration_seconds
      t.integer :status, default: 0, null: false # uploaded status
      t.string :storage_key
      t.string :audio_storage_key

      t.timestamps
    end

    # Indexes for performance
    add_index :videos, :status
    add_index :videos, :created_at
    add_index :videos, :storage_key, unique: true, where: 'storage_key IS NOT NULL'
  end
end
