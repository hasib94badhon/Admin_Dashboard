from django.urls import path,include
from .views import *
from django.conf import settings
from django.conf.urls.static import static


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
    path('api/upload-fb/', fb_page_excel, name='upload-fb'),
    path('api/toggle-status/<int:pk>/', toggle_status, name='toggle_status'),
    path('api/user_toggle_status/<int:pk>/', user_toggle_status, name='user_toggle_status'),
    path('api/user-type-toggle-status/<int:pk>/', user_type_toggle_status, name='user_type_toggle_status'),
    path('api/get-users/', get_users, name='get_users'),
    path('api/download-user/', download_user, name='download_user'),
    path('api/login-superuser/', login_superuser),
    path('api/dashboard-stats/', dashboard_stats, name='dashboard_stats'),
    path('api/deactivated-users/', deactivated_users, name='deactivated_users'),
    path('api/referrals/', referral_list, name='referral-list'),
    path("api/referrals/<int:pk>/update/", update_referral),
    path('api/service-users/', ServiceUserList.as_view(), name='service-users'),
    path('api/shop-users/', ShopUserList.as_view(), name='shop-users'),
    path('api/subscriber-users/', SubscriberListView.as_view(), name='subscriber-users'),
    path('api/create-subscribers/', CreateSubscribersView.as_view(), name='create-subscribers'),
    path('api/term-policy/', TermPolicyAPIView.as_view(), name='term-policy'),
    path('api/contact-info/', ContactInfoAPIView.as_view(), name='contact-info'),
    path('api/toggle-subscriber/<int:sub_id>/', toggle_subscriber, name='toggle-subscriber'),
    path('api/overview-stats/', overview_stats, name='overview-stats'),
    path('api/app-status/', app_status, name='app-status'),
    path('api/insert-topic/', insert_des_cat, name='insert-topic'),
    path('api/reactions/', reactions, name='reactions'),

    # Sub-category CRUD
    path('api/des-categories/', list_des_categories_simple, name='des-categories'),
    path('api/des-sub-categories/', list_des_sub_categories, name='des-sub-categories-list'),
    path('api/des-sub-categories/create/', create_des_sub_category, name='des-sub-categories-create'),
    path('api/des-sub-categories/<int:pk>/update/', update_des_sub_category, name='des-sub-categories-update'),
    path('api/des-sub-categories/<int:pk>/delete/', delete_des_sub_category, name='des-sub-categories-delete'),

    # Suggestion CRUD (quick-suggestion words per sub-category)
    path('api/des-cat-suggestions/', list_des_cat_suggestions, name='des-cat-suggestions-list'),
    path('api/des-cat-suggestions/create/', create_des_cat_suggestion, name='des-cat-suggestions-create'),
    path('api/des-cat-suggestions/<int:pk>/update/', update_des_cat_suggestion, name='des-cat-suggestions-update'),
    path('api/des-cat-suggestions/<int:pk>/delete/', delete_des_cat_suggestion, name='des-cat-suggestions-delete'),

    # ── Notification System ─────────────────────────────────────────────────
    path('api/notification-rules/',                list_notification_rules,       name='notif-rules-list'),
    path('api/notification-rules/create/',         create_notification_rule,      name='notif-rules-create'),
    path('api/notification-rules/<int:pk>/update/', update_notification_rule,     name='notif-rules-update'),
    path('api/notification-rules/<int:pk>/delete/', delete_notification_rule,     name='notif-rules-delete'),

    path('api/broadcasts/',                        list_broadcasts,               name='broadcasts-list'),
    path('api/broadcasts/create/',                 create_broadcast,              name='broadcasts-create'),
    path('api/broadcasts/<int:pk>/send/',          send_broadcast_view,           name='broadcasts-send'),

    path('api/notification-logs/',                 notification_send_logs,        name='notif-logs'),

    # Dropdowns for the notification rule builder
    path('api/notif/des-categories/',              notification_des_categories,      name='notif-des-cats'),
    path('api/notif/des-sub-categories/',          notification_des_sub_categories,  name='notif-des-subcats'),
    path('api/notif/user-categories/',             notification_user_categories,     name='notif-user-cats'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

