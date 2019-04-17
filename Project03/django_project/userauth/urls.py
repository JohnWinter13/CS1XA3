from django.urls import path
from . import views

# routed from root url
urlpatterns = [
    path('signup/', views.add_user , name = 'userauth-signup'),
    path('login/', views.login_user , name = 'userauth-login'),
    path('logout/', views.logout_user , name = 'userauth-logout'),
]
