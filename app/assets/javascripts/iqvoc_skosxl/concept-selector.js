// EntitySelector extension for concept-selection


jQuery(document).ready(function($) {
  "use strict";

  $("input.entity_select").each(function(i, node) {
    new IQVOC.ConceptSelector(node);
  });
});

IQVOC.ConceptSelector = (function($) {

"use strict";

var CS = function(args) {
	var res = IQVOC.EntitySelector.apply(this, arguments);

	this.container.bind("typeahead:cursorchanged", this.onCursorChange)

	return res;
};
CS.prototype = new IQVOC.EntitySelector();

CS.prototype.onCursorChange = function(ev,item) {
	var widget = $(ev.currentTarget).data('widget');
	var target_label = item.label;

	var responder = function(data, status, xhr) {
		var targetSuggestion = $('.tt-cursor:contains('+target_label+')');
		targetSuggestion.append("<small>" + data["broader_relations_string"] + "</small>")
		targetSuggestion.addClass('broader_path_added')
	}
	if(!$('.tt-cursor:first').hasClass('broader_path_added')) {
		$.getJSON(widget.uriTemplate.replace("%7Bid%7D", item.value + "/broader_path"), responder);
	}
};




return CS;

}(jQuery));