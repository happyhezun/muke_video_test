from django.urls import path
from .views.base import Index
from .views.auth import Login, Logout, AdminManger, UpdateAdminStatus
from .views.video import ExternaVideo

urlpatterns = [
    path('', Index.as_view(), name="dashboard_index"),
    path('login/', Login.as_view(), name="login"),
    path('logout/', Logout.as_view(), name="logout"),
    path('admin/', AdminManger.as_view(), name="admin_manger"),
    path('admin/manger/update/status/', UpdateAdminStatus.as_view(), name="admin_update_status"),
    path('video/externa', ExternaVideo.as_view(), name="externa_video"),
]