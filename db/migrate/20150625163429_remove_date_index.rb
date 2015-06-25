class RemoveDateIndex < ActiveRecord::Migration
  def change
    remove_index :precipitations, :date
  end
end
