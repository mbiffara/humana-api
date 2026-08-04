class AddReviewFeedbackToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :review_feedback, :text
    add_column :organizations, :review_feedback_at, :datetime
  end
end
