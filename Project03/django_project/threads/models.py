from django.db import models

class Sub(models.Model):
    """a model to represent a subreddit.
       contains two fields, the name of the subreddit
       and a description for it"""
    name        = models.CharField(max_length=200, unique=True)
    description = models.CharField(max_length=1000)

class Thread(models.Model):
    """a model to represent a thread (a new post or a reply to a post)."""
    title     = models.CharField(max_length=300, null=True) # Title can be empty if it's a reply
    is_master = models.BooleanField() # True if this post is the first in the thread (not a reply)
    date      = models.DateField(auto_now_add=True) # Date of the post
    content   = models.CharField(max_length=5000)
    user      = models.CharField(max_length=100) # name of the user who started the thread
    parent    = models.ForeignKey('self', on_delete=models.CASCADE, null=True) #Null if is_master is true, 
                                                                               #otherwise it is a reply and this tracks the id of the parent Thread
    sub       = models.ForeignKey('sub', on_delete=models.CASCADE) # the subreddit that this thread belongs to
