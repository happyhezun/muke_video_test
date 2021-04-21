from django.views.generic import View
from django.shortcuts import redirect, reverse
from app.libs.base_render import render_to_response
from app.utils.permission import dashboard_auth
from app.model.video import VideoType, FromType, NationalityType, Video, VideoSub, VideoStar, IdentityType
from app.utils.common import check_and_get_video_type

class ExternaVideo(View):
    TEMPLATE = 'dashboard/video/externa_video.html'

    @dashboard_auth
    def get(self, request):
        error = request.GET.get('error', '')
        data = {'error': error}
        videos = Video.objects.exclude(from_to=FromType.custom.value)
        data['videos'] = videos
        return render_to_response(request, self.TEMPLATE, data=data)

    
    def post(self, request):
        name = request.POST.get('name')
        image = request.POST.get('image')
        video_type = request.POST.get('video_type')
        from_to = request.POST.get('from_to')
        nationality = request.POST.get('nationality')
        info = request.POST.get('info')

        if not all([name, image, video_type, from_to, nationality, info]):
            return redirect('{}?error={}'.format(reverse('externa_video'), "缺少必要字段"))

        result = check_and_get_video_type(VideoType, video_type, '非法的视频类型')
        if result.get('code') != 0:
            return redirect('{}?error={}'.format(reverse('externa_video'), result['msg']))

        result = check_and_get_video_type(FromType, from_to, '非法的来源')
        if result.get('code') != 0:
            return redirect('{}?error={}'.format(reverse('externa_video'), result['msg']))

        result = check_and_get_video_type(NationalityType, nationality, '非法的国籍')
        
        Video.objects.create(
            name = name,
            image = image,
            video_type = video_type,
            from_to = from_to,
            nationality = nationality,
            info = info
        )

        print(name, image, video_type, from_to, nationality)
        return redirect(reverse('externa_video'))

class VideoSubView(View):
    TEMPLATE = 'dashboard/video/video_sub.html'

    @dashboard_auth
    def get(self, request, video_id):
        video = Video.objects.get(id=video_id)
        error = request.GET.get('error', '')
        data = {}
        data['video'] = video
        data['error'] = error
        return render_to_response(request, self.TEMPLATE, data=data)

    def post(self, request, video_id):
        url = request.POST.get('url')
        video = Video.objects.get(pk=video_id)
        length = video.video_sub.count()
        # video_subs = VideoSub.objects.filter(video=video)

        VideoSub.objects.create(video=video, url=url, number=length + 1)
        print(url, video_id)
        return redirect(reverse('video_sub', kwargs={'video_id': video_id}))

class VideoStarView(View):
    def post(self, request):
        name = request.POST.get('name')
        identity = request.POST.get('identity')
        video_id = request.POST.get('video_id')

        path_format = '{}'.format(reverse('video_sub', kwargs={'video_id': video_id}))

        if not all([name, identity, video_id]):
            return redirect('{}?error={}'.format(path_format, '缺少字段'))

        result = check_and_get_video_type(IdentityType, identity, '非法的身份')
        if result.get('code') != 0:
            return redirect('{}?error={}'.format(reverse('externa_video'), result['msg']))

        video= Video.objects.get(pk=video_id)
        # VideoStar.objects.create(
        #     video = video,
        #     name = name,
        #     identity = identity
        # )        
        try:
            VideoStar.objects.create(
                video = video,
                name = name,
                identity = identity
            )
        except Exception as e:
            print(e)
            return redirect('{}?error={}'.format(path_format, '创建失败'))
           
        print(name, identity, video_id)
        return redirect(reverse('video_sub', kwargs={'video_id': video_id}))



class StarDelete(View):
    def get(self, request, star_id, video_id):
        star = VideoStar.objects.filter(id=star_id).delete()

        # if star:
        #     star[0].objects.remove()

        return redirect(reverse('video_sub', kwargs={'video_id': video_id}))
