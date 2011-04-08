class AddLabelRelations < ActiveRecord::Migration

  def self.up
    unless table_exists?("label_relations")
      create_table "label_relations", :force => true do |t|
        t.string   "type"
        t.integer  "domain_id"
        t.integer  "range_id"
        t.datetime "created_at"
        t.datetime "updated_at"
      end

      add_index "label_relations", ["domain_id", "range_id", "type"], :name => "index_label_relations_on_domain_id_and_range_id_and_type"
      add_index "label_relations", ["type"], :name => "index_label_relations_on_type"
    end
  end

  def self.down
    if table_exists?("label_relations")
      drop_table("label_relations")
    end
  end

end