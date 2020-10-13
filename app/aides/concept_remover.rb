class ConceptRemover
  def initialize(root_origin)
    @root_concept = Iqvoc::Concept.base_class.find_by_origin(root_origin)
  end

  def run
    if @root_concept
      remove @root_concept
    end
  end

  def remove concept
    remove_narrower_concepts concept
    remove_labels concept
    concept.destroy
  end

  def remove_narrower_concepts concept
    if concept.narrower_relations.any?
      concept.narrower_relations.each do |narrower_relation|
        remove(narrower_relation.target)
      end
    end
 end

 def remove_labels concept
   if concept.labels.any?
     concept.labels.each do |label|
       label.destroy
     end
   end
 end
end
