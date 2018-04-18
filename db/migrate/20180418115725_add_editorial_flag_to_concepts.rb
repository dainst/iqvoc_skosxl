class AddEditorialFlagToConcepts < ActiveRecord::Migration
  def change
  	unless column_exists? :concepts, :editorial_flag
	  add_column :concepts, :editorial_flag, :string
	end
  end
end
