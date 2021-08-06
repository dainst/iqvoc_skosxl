ConceptView.class_eval do
	def notes 
		@concept.notes
	end
end
Rails.application.config.after_initialize do
	

	ConceptsController.class_eval do
		def broader_path
			@concept = Iqvoc::Concept.base_class.where(origin: params[:origin]).first

			if @concept == nil
				render json: {}
				return
			end

			only_published = true
			related_concepts = @concept.related_concepts_for_relation_class(Iqvoc::Concept.broader_relation_class, only_published)
			broader_relations_string = ""

			if related_concepts.any?
				parent = related_concepts.first
				parents = []
				while (parent && !parents.include?(parent))
					parents << parent
					parent = parent.related_concepts_for_relation_class(Iqvoc::Concept.broader_relation_class, only_published).first
				end

				broader_relations_string = parents.map { |concept|
					concept.pref_label
				}.reverse.push(@concept.pref_label).join(" > ").html_safe
			end
			render json: {"broader_relations_string": broader_relations_string}
		end

		def unpublish
			return unless current_user and current_user.owns_role?(:administrator)
			get_concept							
			if @concept.parentless
				@concept.published_at = nil
				@published = 1
				if @concept.save
					flash[:success] = I18n.t('txt.controllers.concept.unpublish_loose_concept.success')
					@published = 0
				else
					flash[:error] = I18n.t('txt.controllers.concept.unpublish_loose_concept.error')
				end
				redirect_to concept_path(published: @published, id: @concept.origin)
			end      		
		end
	end
end