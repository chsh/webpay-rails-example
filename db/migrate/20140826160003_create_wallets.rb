class CreateWallets < ActiveRecord::Migration
  def change
    create_table :wallets do |t|
      t.references :user, index: true
      t.text :customer
      t.string :token, null: false
      t.integer :exp_year, :exp_month, null: false
      t.string :exp_year_and_month, null: false
      t.integer :customer_created_at, null: false
      t.string :fingerprint, null: false
      t.integer :num_errors, default: 0
      t.datetime :last_error_occurred_at
      t.text :last_error
      t.boolean :enabled, default: true
      t.timestamps
    end
    add_index :wallets, :token, unique: true
    add_index :wallets, :fingerprint, unique: true
    add_index :wallets, :customer_created_at
    add_index :wallets, [:exp_year, :exp_month]
    add_index :wallets, :exp_year_and_month
    add_index :wallets, [:user_id, :primary]
    add_index :wallets, :num_errors
    add_index :wallets, :last_error_occurred_at
    add_index :wallets, :enabled
  end
end
