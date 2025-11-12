from django.urls import path
from .views import *


urlpatterns = [
    #path('users', views.data_view, name='data_view'),
    path('api/users', UsersAPIView.as_view(), name='product_api'),
    path('api/userscreate',UserListCreateView.as_view(),name='product_list_create'),
    path('api/cat',CatAPIView.as_view(),name='cat_list'),
    path('api/count',CountAPIView.as_view(),name='count_list'),
    path('insert-cat/', insert_cat, name='insert_cat'),
    path('upload-users/', upload_excel, name='upload-users'),
    path('upload-hotline-numbers/', upload_hotline_numbers_excel, name='upload-hotline-numbers'),
    path('upload-apps/', apps_links_excel, name='upload-apps'),
    path('upload-fb_page/', fb_page_excel, name='upload-fb_page'),
    path('toggle-status/<int:pk>/', toggle_status, name='toggle_status'),
    path('user-toggle-status/<int:pk>/', user_toggle_status, name='user_toggle_status'),
    path('user-type-toggle-status/<int:pk>/', user_type_toggle_status, name='user_type_toggle_status'),
    path('get-users/', get_users, name='get_users'),
    path('download-user/', download_user, name='download_user'),
    path('api/login-superuser/', login_superuser),
    path('api/dashboard-stats/', dashboard_stats, name='dashboard_stats'),
    path('api/deactivated-users/', deactivated_users, name='deactivated_users'),
    
]
