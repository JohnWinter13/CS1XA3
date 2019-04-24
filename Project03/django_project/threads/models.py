from django.db import models

class Thread(models.Model):
    title     = models.CharField(max_length=300, null=True)
    is_master = models.BooleanField() # True if this post is the first in the thread
    date      = models.DateField(auto_now_add=True)
    content   = models.CharField(max_length=5000)
    user      = models.CharField(max_length=100) # name of the user who started the thread
    parent    = models.ForeignKey('self', on_delete=models.CASCADE, null=True)
