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
							if (status == 'success') {
								location.reload();
							} else {
								alert('Error: ' + status + 'the service responded with: ' + response.status + '\n' + response.responseText);
							}
						}
					}
				);
			}
		});
		
		
		//Handle FancyBox
		$(".fancybox-small").fancybox({
				maxWidth	: 400,
				maxHeight	: 400,
				fitToView	: false,
				width			: '400',
				height		: '400',
				autoSize	: true,
				closeClick	: false,
			});
			
			$(".fancybox-large").fancybox({
					maxWidth	: 700,
					maxHeight	: 500,
					fitToView	: false,
					width			: '700',
					height		: '500',
					autoSize	: true,
					closeClick	: false,
				});
});




