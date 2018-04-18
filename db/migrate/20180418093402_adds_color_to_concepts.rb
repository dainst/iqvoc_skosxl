class AddsColorToConcepts < ActiveRecord::Migration
  def change
  	unless column_exists? :concepts, :color
	  add_column :concepts, :color, :string
	end
  end
end
