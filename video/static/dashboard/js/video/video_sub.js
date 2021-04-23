var inputNumber=$('#number');
var inputUrl=$('#url');
var videosubid=$('#videosubid')

$('#update_btn').click(function(){
    // get old value for form
    var videosubId = $(this).attr('data-id');
    // alert(videosubId);
    var videoSubNumber=parseInt($(this).attr('data-number'));
    var videoSubUrl=$(this).attr('data-url');

    inputNumber.val(videoSubNumber);
    inputUrl.val(videoSubUrl);
    videosubid.val(videosubId);
});