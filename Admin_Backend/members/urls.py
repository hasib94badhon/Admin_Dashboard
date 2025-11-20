from django.urls import path
from .views import *


urlpatterns = [
    #path('users', views.data_view, name='data_view'),
    path('api/users', UsersAPIView.as_view(), name='product_api'),
    path('api/userscreate',UserListCreateView.as_view(),name='product_list_create'),
    path('api/cat',CatAPIView.as_view(),name='cat_list'),
    path('api/count',CountAPIView.as_view(),name='count_list'),
    path('api/insert-cat/', insert_cat, name='insert_cat'),
    path('api/upload-users/', upload_excel, name='upload-users'),
    path('api/upload-hotline-numbers/', upload_hotline_numbers_excel, name='upload-hotline-numbers'),
    path('api/upload-apps/', apps_links_excel, name='upload-apps'),
    path('api/upload-fb_page/', fb_page_excel, name='upload-fb_page'),
    path('api/toggle-status/<int:pk>/', toggle_status, name='toggle_status'),
    path('api/user_toggle_status/<int:pk>/', user_toggle_status, name='user_toggle_status'),
    path('api/user-type-toggle-status/<int:pk>/', user_type_toggle_status, name='user_type_toggle_status'),
    path('api/get-users/', get_users, name='get_users'),
    path('api/download-user/', download_user, name='download_user'),
    path('api/login-superuser/', login_superuser),
    path('api/dashboard-stats/', dashboard_stats, name='dashboard_stats'),
    path('api/deactivated-users/', deactivated_users, name='deactivated_users'),
    path('api/referrals/', referral_list, name='referral-list'),
    path("api/referrals/<int:pk>/update/", update_referral)


]

