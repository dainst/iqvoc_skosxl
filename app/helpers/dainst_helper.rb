module DainstHelper
	def broader_path_menu(concept)
		only_published = true
		related_concepts = concept.related_concepts_for_relation_class(Iqvoc::Concept.broader_relation_class, only_published)
		broader_relations_string = ""

		if related_concepts.any?
			parent = related_concepts.first
			parents = []
			while (parent && !parents.include?(parent))
				parents << parent
				parent = parent.related_concepts_for_relation_class(Iqvoc::Concept.broader_relation_class, only_published).first
			end

			broader_relations_string = parents.map { |c|
				link_to_object c, c.pref_label
			}.reverse.push(concept.pref_label).join(" ▸ ").html_safe
		end
		broader_relations_string
	end
end
