from django.urls import path
from . import views

urlpatterns = [
    path('lab7/', views.login, name='auth-lab7'),
]
