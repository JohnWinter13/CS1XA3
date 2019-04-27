from django.http import JsonResponse, HttpResponse
from django.core.serializers.json import Serializer as Builtin_Serializer
from .models import Thread, Sub
import json

class JSONSerializer(Builtin_Serializer):
    def get_dump_object(self, obj):
        metadata = {
            "pkid": obj._get_pk_val(),
        }
        return dict(metadata.items() | self._current.items())

def add_thread(request):
    thread    = json.loads(request.body)
    title     = thread.get("title", None)
    is_master = thread.get("is_master", False)
    date      = thread.get("date")
    content   = thread.get("content", "")
    user      = thread.get("user", "")
    parent    = thread.get("parent", None)

    if content != "" and user != "":
        if parent is None:
            new_thread = Thread(title=title, is_master=is_master, date=date, content=content, user=user, parent=parent)
        else:
            new_thread = Thread(title=title, is_master=is_master, date=date, content=content, user=user, parent=Thread.objects.get(pk=parent))
        new_thread.save() # Add thread to database
        return HttpResponse("Success")

    return HttpResponse("Failure")

def get_threads(request):
    threads_json = JSONSerializer().serialize(Thread.objects.all())
    struct = json.loads(threads_json) 
    data = {"threads": struct}
    return JsonResponse(data)

def get_thread(request):
    json_req = json.loads(request.body)
    thread_id = json_req.get('id', 0)
    thread = Thread.objects.filter(pk=thread_id)
    thread_json = JSONSerializer().serialize(thread)
    struct = json.loads(thread_json) 
    data = {"thread" : struct}
    return JsonResponse(data)

def add_sub(request):
    json_req = json.loads(request.body)
    name = json_req.get("name", None)
    desc = json_req.get("description", False)
    if name !=  "" and sub_name_is_unique(name):
        new_sub = Sub(name=name, description=desc)
        new_sub.save()
        return HttpResponse('Success')
    return HttpResponse('Failure')

def name_is_unique(name):
    for sub in Sub.objects.all():
        if name.lower() == sub.name.lower():
            return False
    return True

def get_subs(request):
    subs_json = JSONSerializer().serialize(Sub.objects.all())
    struct = json.loads(subs_json)
    data = {"subs" : struct}
    return JsonResponse(data)

def get_sub(request):
    json_req = json.loads(request.body)
    sub_id = json_req.get('id', 0)
    sub = Sub.objects.filter(pk=sub_id)
    sub_json = JSONSerializer().serialize(sub)
    struct = json.loads(sub_json) 
    data = {"sub" : struct}
    return JsonResponse(data)
