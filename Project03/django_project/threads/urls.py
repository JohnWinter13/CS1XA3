from django.urls import path
from . import views

# routed from root url
urlpatterns = [
    path('getthreads/', views.get_threads, name='threads-getthreads'),
    path('getthread/', views.get_thread, name='threads-getthread'),
    path('addthread/', views.add_thread, name='threads-addthread'),
]
