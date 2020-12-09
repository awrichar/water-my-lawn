class RemoveDateIndex < ActiveRecord::Migration[4.2]
  def change
    remove_index :precipitations, :date
  end
end
