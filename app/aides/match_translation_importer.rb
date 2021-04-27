class MatchTranslationImporter
	def initialize(translation_target_tree_origin, tranlation_resource_tree_origin)
		@old_tree_origin = tranlation_resource_tree_origin
		@new_tree_origin = translation_target_tree_origin
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
						
						languages_copied = []
						for label in match_target.pref_labels.where.not(language: 'de')
							
							# use label as prefered label
							found_same_language_prefered_label = concept.pref_labels.where("language = '#{label.language}'")
							unless found_same_language_prefered_label.any?
									l = Label::SKOSXL::Base.new(language: label.language, value: label.value, published_at: Time.now)
									l.save()
									concept.pref_labels << l
							else
								# use label as alt label if not present already
								found_same_label_overall = concept.labels.where("language = '#{label.language}' AND value = \"#{label.value}\"")
								unless found_same_label_overall.any?
									l = Label::SKOSXL::Base.new(language: label.language, value: label.value, published_at: Time.now)
									l.save()
									concept.alt_labels << l
								end
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
