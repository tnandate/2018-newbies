# frozen_string_literal: true

class AddStatusColumnToCharge < ActiveRecord::Migration[5.2]
  def change
    add_column :charges, :status, :integer, null: false, default: 'success', after: :amount
    add_column :charges, :ch_id, :string, null: false, after: :status
  end
end
