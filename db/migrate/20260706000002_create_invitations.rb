# Magic-link invitations for new platform users.
# Admins create invitations; invitees accept via a public endpoint.
class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.string :email, null: false
      t.string :token, null: false
      t.string :role, null: false
      t.references :organization, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.datetime :accepted_at
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, :email
  end
end
