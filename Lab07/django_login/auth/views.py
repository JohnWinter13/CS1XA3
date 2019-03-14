
from django.shortcuts import render
from django.http import HttpResponse

def login(request):
    dic = request.POST
    user = dic.get('username', '')
    passw = dic.get('password', '')
    if user == 'Jimmy' and passw == 'Hendrix':
        return HttpResponse('Cool')
    return HttpResponse('Bad User Name')


