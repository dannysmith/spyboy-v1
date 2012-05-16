/* Author: Danny Smith http://dasmith.com
*/

$(function(){
	
	
	//Handle clicks to links with class .delete.
	$('a.delete').click(function(e){
			e.preventDefault();
			$.ajax(
				{
					url: this.getAttribute('href'),
					type: 'DELETE',
					async: false,
					complete: function(response, status) {
						if (status == 'success') {
							location.reload();
						} else {
							alert('Error: the service responded with: ' + response.status + '\n' + response.responseText);
						}
					}
				}
			);
		});
		
		
		//Handle FancyBox
		$(".fancybox").fancybox({
				maxWidth	: 800,
				maxHeight	: 600,
				fitToView	: false,
				width			: '500px',
				height		: '500px',
				autoSize	: true,
				closeClick	: false,
			});
});




