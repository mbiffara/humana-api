# Optional property video for the onboarding photo step (LOG-137). The hotel
# hosts the video elsewhere (YouTube, Vimeo, Instagram) and only stores the
# link, so the column is nullable and existing rows stay valid.
class AddVideoUrlToHotels < ActiveRecord::Migration[8.0]
  def change
    add_column :hotels, :video_url, :string
  end
end
