# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey and OneToOneField has `on_delete` set to the desired behavior
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from django.db import models



class Users(models.Model):
    user_id = models.AutoField(primary_key=True)
    reg_id = models.IntegerField()
    # cat_id = models.IntegerField()
    cat = models.ForeignKey('Cat', models.DO_NOTHING, db_column='cat_id')
    name = models.TextField()
    phone = models.CharField(max_length=255)
    description = models.TextField()
    location = models.TextField()
    photo = models.TextField(blank=True, null=True)
    user_type = models.CharField(max_length=255)

    status = models.BooleanField()
    user_shared = models.IntegerField()
    user_viewed = models.IntegerField()
    user_called = models.IntegerField()
    user_total_post = models.IntegerField()
    user_logged_date = models.DateTimeField(blank=True, null=True)
    call_status = models.CharField(max_length=10, blank=True, null=True)
    nid = models.TextField()
    tin = models.TextField()
    self_referral_id = models.CharField(max_length=8)
    reg_referral_id = models.CharField(max_length=8)
    email = models.CharField(max_length=255)
    is_active = models.IntegerField()
    deactivated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'users'

class AboutInfo(models.Model):
    about = models.TextField(blank=True, null=True)
    founders = models.TextField(blank=True, null=True)
    sponsors = models.TextField(blank=True, null=True)
    office_address = models.TextField(blank=True, null=True)
    contact = models.TextField(blank=True, null=True)
    goals = models.TextField(blank=True, null=True)
    quote = models.TextField(blank=True, null=True)
    last_updated = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'about_info'


class Apps(models.Model):
    app_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=255)
    web = models.CharField(max_length=255)
    address = models.CharField(max_length=255)
    photo = models.CharField(max_length=255)
    category = models.CharField(max_length=255)
    android_link = models.TextField(blank=True, null=True)
    ios_link = models.TextField(blank=True, null=True)
    deeplink = models.CharField(max_length=255, blank=True, null=True)
    visit_count = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'apps'


class AuthGroup(models.Model):
    name = models.CharField(unique=True, max_length=150)

    class Meta:
        managed = False
        db_table = 'auth_group'


class AuthGroupPermissions(models.Model):
    id = models.BigAutoField(primary_key=True)
    group = models.ForeignKey(AuthGroup, models.DO_NOTHING)
    permission = models.ForeignKey('AuthPermission', models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'auth_group_permissions'
        unique_together = (('group', 'permission'),)


class AuthPermission(models.Model):
    name = models.CharField(max_length=255)
    content_type = models.ForeignKey('DjangoContentType', models.DO_NOTHING)
    codename = models.CharField(max_length=100)

    class Meta:
        managed = False
        db_table = 'auth_permission'
        unique_together = (('content_type', 'codename'),)


class AuthUser(models.Model):
    password = models.CharField(max_length=128)
    last_login = models.DateTimeField(blank=True, null=True)
    is_superuser = models.IntegerField()
    username = models.CharField(unique=True, max_length=150)
    first_name = models.CharField(max_length=150)
    last_name = models.CharField(max_length=150)
    email = models.CharField(max_length=254)
    is_staff = models.IntegerField()
    is_active = models.IntegerField()
    date_joined = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'auth_user'


class AuthUserGroups(models.Model):
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(AuthUser, models.DO_NOTHING)
    group = models.ForeignKey(AuthGroup, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'auth_user_groups'
        unique_together = (('user', 'group'),)


class AuthUserUserPermissions(models.Model):
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(AuthUser, models.DO_NOTHING)
    permission = models.ForeignKey(AuthPermission, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'auth_user_user_permissions'
        unique_together = (('user', 'permission'),)


class CallList(models.Model):
    call_id = models.AutoField(primary_key=True)
    call_time = models.DateTimeField()
    call_user = models.ForeignKey('Users', models.DO_NOTHING)
    user = models.ForeignKey('Users', models.DO_NOTHING, related_name='calllist_user_set')
    call_count = models.BigIntegerField()

    class Meta:
        managed = False
        db_table = 'call_list'
        unique_together = (('call_user', 'user'),)


class CallListBackup(models.Model):
    call_id = models.IntegerField()
    call_time = models.DateTimeField()
    call_user_id = models.IntegerField()
    user_id = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'call_list_backup'


class Cat(models.Model):
    cat_id = models.AutoField(primary_key=True)
    cat_name = models.CharField(max_length=255, blank=True, null=True)
    cat_logo = models.CharField(max_length=255, blank=True, null=True)
    user_count = models.IntegerField(blank=True, null=True)
    cat_used = models.IntegerField(blank=True, null=True)
    status = models.BooleanField(default=True)
    yes_service = models.IntegerField()
    yes_shop = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'cat'


class Comment(models.Model):
    com_id = models.AutoField(primary_key=True)
    com_text = models.TextField()
    com_time = models.DateTimeField()
    com_user = models.ForeignKey('Users', models.DO_NOTHING)
    post = models.ForeignKey('Post', models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'comment'


class DesCat(models.Model):
    des_cat_id = models.AutoField(primary_key=True)
    des_cat_name = models.CharField(max_length=255)
    des_cat_status = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'des_cat'


class DesSubCat(models.Model):
    des_sub_cat_id = models.AutoField(primary_key=True)
    des_cat        = models.ForeignKey(DesCat, on_delete=models.CASCADE,
                                       db_column='des_cat_id', related_name='sub_cats')
    name_bn        = models.CharField(max_length=120)
    name_en        = models.CharField(max_length=120, blank=True, null=True)
    emoji          = models.CharField(max_length=10, blank=True, null=True)
    sort_order     = models.IntegerField(default=0)

    class Meta:
        managed = False
        db_table = 'des_sub_cat'
        ordering = ['des_cat_id', 'sort_order']


class DesCatSuggestion(models.Model):
    id              = models.AutoField(primary_key=True)
    des_sub_cat     = models.ForeignKey(DesSubCat, on_delete=models.CASCADE,
                                        db_column='des_sub_cat_id', related_name='suggestions')
    suggestion_text = models.CharField(max_length=255)
    sort_order      = models.IntegerField(default=0)
    created_at      = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = False
        db_table = 'des_cat_suggestion'
        ordering = ['des_sub_cat_id', 'sort_order']


class Description(models.Model):
    des_id = models.AutoField(primary_key=True)
    user_id = models.IntegerField()
    time = models.DateTimeField(blank=True, null=True)
    des = models.TextField()
    des_photo = models.CharField(max_length=255, blank=True, null=True)
    des_view = models.IntegerField()
    des_com = models.IntegerField()
    des_cat = models.ForeignKey(DesCat, models.DO_NOTHING, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'description'


class DjangoAdminLog(models.Model):
    action_time = models.DateTimeField()
    object_id = models.TextField(blank=True, null=True)
    object_repr = models.CharField(max_length=200)
    action_flag = models.PositiveSmallIntegerField()
    change_message = models.TextField()
    content_type_id = models.IntegerField(blank=True, null=True)
    user_id = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'django_admin_log'


class DjangoContentType(models.Model):
    app_label = models.CharField(max_length=100)
    model = models.CharField(max_length=100)

    class Meta:
        managed = False
        db_table = 'django_content_type'
        unique_together = (('app_label', 'model'),)


class DjangoMigrations(models.Model):
    id = models.BigAutoField(primary_key=True)
    app = models.CharField(max_length=255)
    name = models.CharField(max_length=255)
    applied = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'django_migrations'


class DjangoSession(models.Model):
    session_key = models.CharField(primary_key=True, max_length=40)
    session_data = models.TextField()
    expire_date = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'django_session'


class FavoriteUsers(models.Model):
    fav_id = models.AutoField(primary_key=True)
    user_id = models.IntegerField()
    fav_users = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'favorite_users'


class FbPage(models.Model):
    page_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=255)
    cat = models.CharField(max_length=255)
    photo = models.CharField(max_length=255)
    phone = models.IntegerField()
    link = models.CharField(max_length=255)
    location = models.CharField(max_length=255)
    time = models.DateTimeField(auto_now_add=True)
    visit_count = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'fb_page'


class HotlineNumbers(models.Model):
    name = models.CharField(max_length=255)
    phone = models.CharField(max_length=255)
    category = models.CharField(max_length=255)
    photo = models.CharField(max_length=255)

    class Meta:
        managed = False
        db_table = 'hotline_numbers'


class Location(models.Model):
    loc_id = models.AutoField(primary_key=True)
    user_id = models.IntegerField(unique=True)
    lat = models.CharField(max_length=50)
    lon = models.CharField(max_length=50)
    address = models.TextField()
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'location'


class Notifications(models.Model):
    user_id = models.IntegerField()
    type = models.CharField(max_length=7)
    detail_user = models.IntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_read = models.IntegerField(blank=True, null=True)
    detail_post_id = models.IntegerField()
    service_id = models.IntegerField()
    shop_id = models.IntegerField()
    is_service = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'notifications'


class Post(models.Model):
    post_id = models.AutoField(primary_key=True)
    cat_id = models.IntegerField()
    user_id = models.IntegerField()
    post_des = models.TextField(blank=True, null=True)
    post_media = models.TextField(blank=True, null=True)
    post_comments = models.IntegerField()
    post_viewed = models.IntegerField()
    post_time = models.DateTimeField(blank=True, null=True)
    post_main_description = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'post'


class Reg(models.Model):
    reg_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=255)
    phone = models.CharField(max_length=11)
    password = models.CharField(max_length=255)
    created_date = models.DateTimeField()
    secret_number = models.CharField(max_length=10, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'reg'


class Service(models.Model):
    service_id = models.AutoField(primary_key=True)
    cat_id = models.ForeignKey(Cat, models.DO_NOTHING, db_column='cat_id')
    name = models.CharField(max_length=255)
    location = models.CharField(max_length=255)
    description = models.TextField()
    photo = models.CharField(max_length=255)
    phone = models.IntegerField()
    date_time = models.DateTimeField()
    user_id = models.ForeignKey(Users, models.DO_NOTHING, db_column='user_id')

    @property
    def user_location(self):
        return Location.objects.filter(user_id=self.user_id_id).first()

    class Meta:
        managed = False
        db_table = 'service'


class Shop(models.Model):
    shop_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=255)
    cat_id = models.ForeignKey(Cat, models.DO_NOTHING, db_column='cat_id')
    location = models.CharField(max_length=255)
    description = models.TextField()
    phone = models.IntegerField()
    photo = models.CharField(max_length=255)
    date_time = models.DateTimeField()
    # user = models.ForeignKey('Users', models.DO_NOTHING)
    user_id = models.ForeignKey(Users, models.DO_NOTHING, db_column='user_id')

    @property
    def user_location(self):
        return Location.objects.filter(user_id=self.user_id_id).first()

    class Meta:
        managed = False
        db_table = 'shop'


class Subscribers(models.Model):
    sub_id = models.AutoField(primary_key=True)
    user_id = models.IntegerField()
    reg_id = models.IntegerField()
    cat_id = models.IntegerField()
    type = models.CharField(max_length=255)
    requested_at = models.DateTimeField(blank=True, null=True)
    last_notified_at = models.DateTimeField(blank=True, null=True)
    last_pay = models.DateTimeField(blank=True, null=True)
    payment_history = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'subscribers'


class TermPolicy(models.Model):
    term_id = models.AutoField(primary_key=True)
    des = models.TextField()

    class Meta:
        managed = False
        db_table = 'term_policy'


class ContactInfo(models.Model):
    id       = models.IntegerField(primary_key=True, default=1)
    phone    = models.CharField(max_length=50, blank=True, default='')
    email    = models.CharField(max_length=100, blank=True, default='')
    address  = models.CharField(max_length=255, blank=True, default='')
    website  = models.CharField(max_length=255, blank=True, default='')
    facebook = models.CharField(max_length=255, blank=True, default='')
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        managed = False
        db_table = 'contact_info'


class ThoughtComment(models.Model):
    com_id = models.AutoField(primary_key=True)
    com_text = models.TextField()
    com_time = models.DateTimeField(blank=True, null=True)
    com_user_id = models.IntegerField()
    des_id = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'thought_comment'


class UserDeactivations(models.Model):
    user = models.ForeignKey('Users', models.DO_NOTHING)
    reason = models.TextField()
    deactivated_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'user_deactivations'


class UserReferrals(models.Model):
    id = models.BigAutoField(primary_key=True)
    referral_id = models.CharField(max_length=8)
    referrer_user_id = models.IntegerField()
    referred_user_id = models.IntegerField(unique=True)
    referred_cat_id = models.IntegerField()
    points = models.IntegerField()
    payment_status = models.CharField(max_length=100)
    created_at = models.DateTimeField()
    verification = models.CharField(max_length=20)
    paid_at = models.DateTimeField(null=True, blank=True)


    class Meta:
        managed = False
        db_table = 'user_referrals'





class ViewList(models.Model):
    view_id = models.AutoField(primary_key=True)
    view_time = models.DateTimeField()
    view_user_id = models.IntegerField()
    user_id = models.IntegerField()
    view_count = models.BigIntegerField()

    class Meta:
        managed = False
        db_table = 'view_list'
        unique_together = (('view_user_id', 'user_id'),)


# ── Notification System ──────────────────────────────────────────────────────

class NotificationRule(models.Model):
    rule_id        = models.AutoField(primary_key=True)
    rule_name      = models.CharField(max_length=255)
    des_cat_id     = models.IntegerField()
    des_sub_cat_id = models.IntegerField(default=0)
    target_cat_ids = models.TextField(default='[]')
    is_active      = models.BooleanField(default=True)
    created_at     = models.DateTimeField(auto_now_add=True)
    updated_at     = models.DateTimeField(auto_now=True)

    class Meta:
        managed  = False
        db_table = 'notification_rules'


class BroadcastNotification(models.Model):
    STATUS_CHOICES = [
        ('draft',   'Draft'),
        ('sending', 'Sending'),
        ('sent',    'Sent'),
        ('failed',  'Failed'),
    ]
    title          = models.CharField(max_length=255)
    body           = models.TextField()
    target_cat_ids = models.TextField(default='[]')
    sent_count     = models.IntegerField(default=0)
    failed_count   = models.IntegerField(default=0)
    status         = models.CharField(max_length=20, choices=STATUS_CHOICES,
                                      default='draft')
    created_by     = models.CharField(max_length=100, default='admin')
    sent_at        = models.DateTimeField(null=True, blank=True)
    created_at     = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed  = False
        db_table = 'broadcast_notifications'


class NotificationSendLog(models.Model):
    TRIGGER_CHOICES = [('post', 'Post'), ('broadcast', 'Broadcast'),
                       ('new_user', 'New User'), ('subscription', 'Subscription')]
    STATUS_CHOICES  = [('sent', 'Sent'), ('failed', 'Failed'),
                       ('no_token', 'No Token')]
    log_id        = models.AutoField(primary_key=True)
    trigger_type  = models.CharField(max_length=20, choices=TRIGGER_CHOICES)
    trigger_id    = models.IntegerField()
    triggered_by  = models.IntegerField(default=0)
    rule_id       = models.IntegerField(null=True, blank=True)
    title         = models.CharField(max_length=255)
    body          = models.TextField()
    target_cats   = models.TextField(null=True, blank=True)
    sent_count    = models.IntegerField(default=0)
    failed_count  = models.IntegerField(default=0)
    sent_at       = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed  = False
        db_table = 'notification_send_log'
