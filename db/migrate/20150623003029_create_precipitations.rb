class CreatePrecipitations < ActiveRecord::Migration
  def change
    create_table :precipitations do |t|
      t.date :date, null: false
      t.string :city, null: false
      t.string :state, null: false
      t.float :precipitation
      t.boolean :forecast

      t.timestamps null: false
    end

    add_index :precipitations, :date, unique: true
  end
end
