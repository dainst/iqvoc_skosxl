jQuery(document).ready(function($) {
	"use strict";
	$(".concept-mapper input.tt-input").each(function(item, node) {
		$(node.parentElement).bind("typeahead:cursorchanged", function(ev,item){
			var target_label = item.label;

			var responder = function(data, status, xhr) {
				var targetSuggestion = $('.tt-cursor:contains('+target_label+')');
				targetSuggestion.append("<small>" + data["broader_relations_string"] + "</small>")
				targetSuggestion.addClass('broader_path_added')
			}
			if(!$('.tt-cursor:first').hasClass('broader_path_added')) {
				var loc = window.location
				var current_language = loc.pathname.split("/")[1]
				var origin = item.value.split("/")[3]
				$.getJSON(loc.origin + "/" + current_language + "/concepts/" + origin + "/broader_path.json", responder);
			}
		});
	});
});

