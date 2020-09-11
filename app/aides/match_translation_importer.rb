class MatchTranslationImporter
	def initialize()
		@old_tree_origin = "_05805030"
		@new_tree_origin = "_fe65f286"
		@root_concept = Iqvoc::Concept.base_class.find_by_origin(@new_tree_origin)
	end
	
	def run
		if @root_concept
			find_and_copy_translations @root_concept
		end
	end

	def find_and_copy_translations concept
		if concept.match_skos_exact_matches.any?
			concept.match_skos_exact_matches.each do |exact_match|
				puts " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
				puts "MATCH VALUE: " + exact_match.value
				is_local = exact_match.value.split("http://thesauri.dainst.org/")[1]

				if is_local
					match_target_concept_origin = exact_match.value.split("/").last
					puts "Exact Match for #{match_target_concept_origin} in #{concept.origin} found"

					# matching target could be nil!
					match_target = Iqvoc::Concept.base_class.find_by_origin(match_target_concept_origin)
					next unless match_target

					if broader_relations_contain_old_tree(match_target)
						puts "match-target is part of old tree!"
						# 
						languages_copied = []
						for label in match_target.pref_labels.where.not(language: 'de')
							unless languages_copied.include? label.language
								concept.pref_labels.create(language: label.language, value: label.value, published_at: Time.now)
								# puts Label::SKOSXL::Base.new(language: label.language, value: label.value, published_at: Time.now)
								languages_copied << label.language
							end
						end
					end
				end
			end
		end

		#child concepts
		concept.narrower_relations.each do |narrower_relation|
			find_and_copy_translations(narrower_relation.target)
		end
	end


	def broader_relations_contain_old_tree(concept) 
		related_concepts = concept.related_concepts_for_relation_class(Iqvoc::Concept.broader_relation_class, true)

		if related_concepts.any?
			parent = related_concepts.first
			parents = []
			while (parent && !parents.include?(parent))
				parents << parent
				parent = parent.related_concepts_for_relation_class(Iqvoc::Concept.broader_relation_class, true).first
			end

			for p in parents
				return true if p.origin == @old_tree_origin
			end

			return false
		end
	end
end
