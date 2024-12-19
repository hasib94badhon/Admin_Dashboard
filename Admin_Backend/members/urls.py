from django.urls import path
from .views import *


urlpatterns = [
    #path('users', views.data_view, name='data_view'),
    path('api/users', UsersAPIView.as_view(), name='product_api'),
    path('api/userscreate',UserListCreateView.as_view(),name='product_list_create'),
    path('api/cat',CatAPIView.as_view(),name='cat_list'),
    path('api/count',CountAPIView.as_view(),name='count_list'),
    path('insert-cat/', insert_cat, name='insert_cat'),
    path('upload-users/', UploadUsersView.as_view(), name='upload-users'),
    
]
