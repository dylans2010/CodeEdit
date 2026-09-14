from django.urls import path
from django.http import JsonResponse

def home(request):
    return JsonResponse({'project': '{{PROJECT_NAME}}', 'status': 'ready'})

urlpatterns = [
    path('', home),
]
