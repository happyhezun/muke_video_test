from django.views.generic import View
from django.shortcuts import redirect, reverse
from app.libs.base_render import render_to_response
from app.utils.permission import dashboard_auth

class ExternaVideo(View):
    TEMPLATE = 'dashboard/video/externa_video.html'

    @dashboard_auth
    def get(self, request):
        error = request.GET.get('error', '')
        data = {'error': error}
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

        print(name, image, video_type, from_to, nationality)
        return redirect(reverse('externa_video'))




