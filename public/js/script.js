/* Author: Danny Smith http://dasmith.com
*/

$(function(){
	
	
	//Handle clicks to links with class .delete.
	$('a.delete').click(function(e){
		e.preventDefault();
		if (confirm("Are you sure?")) {
			$.ajax(
				{
					url: this.getAttribute('href'),
					type: 'DELETE',
					async: false,
					complete: function(response, status) {
						//alert(status);
						if (status == 'success') {
							location.reload();
						} else {
							alert('Error: the service responded with: ' + response.status + '\n' + response.responseText);
						}
					}
				}
			);
		}
	});
				
		
	//Handle FancyBoxes
	$(".fancybox-small").fancybox({
	maxWidth	: 374,
	maxHeight	: 210,
	fitToView	: false,
	width			: '374',
	height		: '210',
	autoSize	: false,
	closeClick	: false
	});

	$(".fancybox-large").fancybox({
		maxWidth	: 768,
		maxHeight	: 480,
		fitToView	: false,
		width			: '768',
		height		: '480',
		autoSize	: false,
		closeClick	: false
	});
	
	$(".fancybox").fancybox({
		maxWidth	: 1000,
		maxHeight	: 700,
		fitToView	: false,
		autoSize	: true,
		closeClick	: false
	});


	//Handle form validations
	$('form.validate').simpleValidate({
		errorClass: 'validation-error', 
	  errorText: 'Please include a {label}', //Structure for the error message text, {label} will be replaced with the associated label text  
	  emailErrorText: 'Please enter a valid email address', //Structure for the email error message text, {label} will be replaced with the associated label text  
	  errorElement: 'p', //Element to use for the error message text  
	  removeLabelChar: '*', //If there is an extra character in the label to denote a required field, strip it out  
	  inputErrorClass: 'validation-error', //Class to add to an input when it is marked as having an error  
	  completeCallback: '' //Function to call once the form is error-free  
	});

	//Handle fading out of flash messages
	$('#flash').delay(1600).animate({opacity: 0, height: 0}, 1000);

	//Move image2 up a bit in DOM.
	// Calculates the middle element in the description html and moves the image to there.
	$(".image2").show();
	
	$.each($("article"), function(){
		$($(this).find(".show-description").children()[Math.round($(this).find(".show-description").children().length/2)-1]).before($(this).find(".image2"));
	});
	
	//Toggle alternate header
	$(".toggle-header").click(function() {
		$.ajax({url: "/toggleheader",
						type: 'POST',
						async: false,
						complete: function(response, status) {
							$('header[role]').toggleClass("alternate");
						}
					});
	});
	
	
	//============== ALL JS FOR MODAL WINDOWS SHOULD GO BELOW =============
	
	//Handle Date Picker
	AnyTime.picker("datetimefield",
	      { format: "%Y-%m-%dT%H:%i:%s%+",
	        formatUtcOffset: "%: (%@)",
	        hideInput: true,
	        askSecond: false,
	        placement: "inline" });
	
	
	//Handle Rich Text Editor
	$('textarea.rte-editor').rte({
		content_css_url: "/css/rte.css",
		media_url: "/img/"
	});
});




