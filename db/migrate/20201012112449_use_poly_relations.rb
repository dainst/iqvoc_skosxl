class UsePolyRelations < ActiveRecord::Migration
  def self.up
      Concept::Relation::Base
        .where('type="Concept::Relation::SKOS::Broader::Mono"')
        .update_all(type: 'Concept::Relation::SKOS::Broader::Poly')
  end

  def self.down
    Concept::Relation::Base
        .where('type="Concept::Relation::SKOS::Broader::Poly"')
        .update_all(type: 'Concept::Relation::SKOS::Broader::Mono')
  end
end

