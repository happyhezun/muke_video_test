from django.urls import path
from .views.base import Base

urlpatterns = [
    path('base', Base.as_view())
]