module DainstHelper
	def broader_path_menu(concept)
		only_published = true
		related_concepts = concept.related_concepts_for_relation_class(Iqvoc::Concept.broader_relation_class, only_published)
		broader_relations_links = ""

		if related_concepts.any?
			parent = related_concepts.first
			parents = []
			while (parent && !parents.include?(parent))
				parents << parent
				parent = parent.related_concepts_for_relation_class(Iqvoc::Concept.broader_relation_class, only_published).first
			end

			broader_relations_links = parents.map { |c|
				link_to_object( c, c.pref_label)
			}.reverse.push(
				link_to_object(concept, concept.pref_label)
				).join(" ▸ ").html_safe

		end
		broader_relations_links
	end

	def broader_paths_menu_sorted(concepts)
		return "No concepts found" if concepts.count == 0
		return "<li>#{ broader_path_menu(concept) }</li>" if concepts.count == 1

		broader_concept_menus = {}
		menu_html = ""
	    for concept in concepts
    	    link_menu = broader_path_menu(concept)
		    broader_concept_menus[strip_tags(link_menu)] = link_menu
	    end
	  	sorted = broader_concept_menus.sort_by{|k,v| k[0..36].downcase}
	    for v in sorted
	        menu_html += "<li>#{ v[1] }</li>"
	    end
	    menu_html
	end
end
