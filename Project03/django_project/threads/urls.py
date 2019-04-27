from django.urls import path
from . import views

# routed from root url
urlpatterns = [
    path('getthreads/', views.get_threads, name='threads-getthreads'),
    path('getthread/', views.get_thread, name='threads-getthread'),
    path('addthread/', views.add_thread, name='threads-addthread'),
    path('addsub/', views.add_sub, name='threads-addsub'),
    path('getsubs/', views.get_subs, name='threads-getsubs'),
    path('getsub/', views.get_sub, name='threads-getsub')
]
