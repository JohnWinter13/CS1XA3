from django.http import JsonResponse, HttpResponse
from django.core.serializers.json import Serializer as Builtin_Serializer
from .models import Thread, Sub
import json

class JSONSerializer(Builtin_Serializer):
    """A JSONSerializer to make parsing in Elm simpler.
       Returns a dictionary like {"pkid" : integer, "objectprop1" : value1, "objectprop2" : value2}"""
    def get_dump_object(self, obj):
        metadata = {
            "pkid": obj._get_pk_val(), #The id of the object
        }
        return dict(metadata.items() | self._current.items())

def add_thread(request):
    """Given a JSON request, attempts to create a new thread.
       Not all Thread variables are required (see below)."""
    thread    = json.loads(request.body) #Get JSON
    title     = thread.get("title", None) #not required
    is_master = thread.get("is_master", False) #required
    date      = thread.get("date") #not required (automatically set by model)
    content   = thread.get("content", "") #required
    user      = thread.get("user", "") #required
    parent    = thread.get("parent", None) #not required
    sub       = thread.get("sub", None) #required

    if content != "" and user != "" and sub is not None and sub > 0: #Validate request
        if parent is None: #This means we are making a reply, and not a new thread (set parent to None)
            new_thread = Thread(
                title=title, 
                is_master=is_master,
                date=date,
                content=content, 
                user=user, 
                parent=parent, 
                sub=Sub.objects.get(pk=sub)
            )
        else: #We are making a new thread, find corresponding parent object by id
            new_thread = Thread(
                title=title, 
                is_master=is_master, 
                date=date, 
                content=content, 
                user=user, 
                parent=Thread.objects.get(pk=parent), 
                sub=Sub.objects.get(pk=sub)
            )
        new_thread.save() # Add thread to database
        return HttpResponse("Success")

    return HttpResponse("Failure")

def get_threads(request):
    """Returns a JsonResponse containing all Thread objects"""
    threads_json = JSONSerializer().serialize(Thread.objects.all())
    struct = json.loads(threads_json) 
    data = {"threads": struct}
    return JsonResponse(data)

def get_thread(request):
    """Accepts a JSON request with { "id": integer } and returns only the Thread with the specified id"""
    json_req = json.loads(request.body)
    thread_id = json_req.get('id', 0)
    thread = Thread.objects.filter(pk=thread_id)
    thread_json = JSONSerializer().serialize(thread)
    struct = json.loads(thread_json) 
    data = {"thread" : struct}
    return JsonResponse(data)

def add_sub(request):
    """Accepts a JSON request with { "name": "string", "description": "string" }
        and attempts to add a sub to the database"""
    json_req = json.loads(request.body)
    name = json_req.get("name", None)
    desc = json_req.get("description", False)
    if name !=  "" and sub_name_is_unique(name): #Must not have subreddits with the same name
        new_sub = Sub(name=name, description=desc) #create Sub object
        new_sub.save() #add to database
        return HttpResponse('Success')
    return HttpResponse('Failure')

def sub_name_is_unique(name):
    """Searches all Sub objects, and if a Sub is found with the same name, returns False.
        Not case sensitive."""
    for sub in Sub.objects.all():
        if name.lower() == sub.name.lower():
            return False
    return True

def get_subs(request):
    """Returns a JsonResponse containing all Sub objects"""
    subs_json = JSONSerializer().serialize(Sub.objects.all())
    struct = json.loads(subs_json)
    data = {"subs" : struct}
    return JsonResponse(data)

def get_sub(request):
    """Accepts a JSON request with { "id": integer } and returns only the Sub with the specified id"""
    json_req = json.loads(request.body)
    sub_id = json_req.get('id', 0)
    sub = Sub.objects.filter(pk=sub_id)
    sub_json = JSONSerializer().serialize(sub)
    struct = json.loads(sub_json) 
    data = {"sub" : struct}
    return JsonResponse(data)
