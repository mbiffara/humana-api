# "Property identity" (LOG-157) grows in two directions. The hotel gains a
# short free-text pitch ("what makes your property special?"), and the
# organization gains the verification block HUMANA needs before approving a
# property: the legal identity of the company behind it, who is responsible
# for it, where it can be found online, and the document plus declaration
# that back the claim of ownership or representation.
class AddPropertyIdentityFields < ActiveRecord::Migration[8.0]
  def change
    add_column :hotels, :highlight, :text

    add_column :organizations, :business_name, :string
    add_column :organizations, :primary_contact_role, :string
    add_column :organizations, :commercial_registration, :string
    add_column :organizations, :social_links, :jsonb, default: {}, null: false
    add_column :organizations, :ownership_document_url, :string
    add_column :organizations, :authorization_declared_at, :datetime
  end
end
