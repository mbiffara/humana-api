# Login accounts. Every user belongs to an organization and authenticates with
# email + bcrypt password, exchanged for a JWT by the sessions endpoint.
class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name
      t.string :role, null: false, default: "member" # owner | member | admin
      t.string :locale, null: false, default: "en"   # en | es | pt
      t.datetime :last_login_at

      t.timestamps
    end

    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"
  end
end
