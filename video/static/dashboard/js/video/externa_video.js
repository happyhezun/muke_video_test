var videoEreaStatic = false
var videoEditArea = $("#video-edit-area")

$('#open-add-video-btn').click(function(){
    // alert('1');
    if (!videoEreaStatic){
        videoEditArea.show();
        videoEreaStatic = true;
    } else {
        videoEditArea.hide();
        videoEreaStatic = false;
    }
})