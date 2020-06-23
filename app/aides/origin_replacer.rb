class OriginReplacer
	def initialize(root_origin)
		@root_concept = Iqvoc::Concept.base_class.find_by_origin(root_origin)
	end
	
	def run
		if @root_concept
			replace_in_narrower_concepts @root_concept
		end
	end

	def replace_in_narrower_concepts concept
		if concept.narrower_relations.any?
			concept.narrower_relations.each do |narrower_relation|
				replace(narrower_relation.target)
			end
		end
	end

	def replace concept
		note = Note::SKOS::EditorialNote.create(value: "former origin: " + concept.origin, owner_type: concept.type, language: "de")
		concept.notes << note
		if note
			concept.origin = Origin.new().to_s
			concept.save
		end
		replace_in_narrower_concepts(concept)
	end
end