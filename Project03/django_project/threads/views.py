from django.http import JsonResponse, HttpResponse
from django.core import serializers
from .models import Thread
import json

def add_thread(request):
    thread    = json.loads(request.body)
    title     = thread.get("title", None)
    is_master = thread.get("is_master", False)
    date      = thread.get("date")
    content   = thread.get("content", "")
    user      = thread.get("user", "")
    parent    = thread.get("parent", None)

    if content != "" and user != "":
        new_thread = Thread(title=title, is_master=is_master, date=date, content=content, user=user, parent=parent)
        new_thread.save() # Add thread to database
        return HttpResponse("Success")

    return HttpResponse("Failure")

def get_threads(request):
    threads_json = serializers.serialize("json", Thread.objects.all())
    struct = json.loads(threads_json) 
    data = {"threads": struct}
    return JsonResponse(data)

def get_thread(request):
    json_req = json.loads(request.body)
    thread_id = json_req.get('id', 0)
    thread = Thread.objects.filter(pk=thread_id)
    thread_json = serializers.serialize("json", thread)
    struct = json.loads(thread_json) 
    data = {"thread" : struct}
    return JsonResponse(data)
