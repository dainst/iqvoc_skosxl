silence_warnings do
  Iqvoc::Label = nil
end

Iqvoc.searchable_class_names = ['Labeling::SKOSXL::Base'] +
    Iqvoc::Concept.labeling_class_names.keys + Iqvoc::Concept.note_class_names
