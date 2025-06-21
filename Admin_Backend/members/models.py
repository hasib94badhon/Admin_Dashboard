# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey and OneToOneField has `on_delete` set to the desired behavior
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from django.db import models



class Apps(models.Model):
    app_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=255)
    web = models.CharField(max_length=255)
    address = models.CharField(max_length=255)
    photo = models.CharField(max_length=255)
    category = models.CharField(max_length=255)

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

    class Meta:
        managed = False
        db_table = 'call_list'


class Cat(models.Model):
    cat_id = models.AutoField(primary_key=True)
    cat_name = models.CharField(max_length=255, blank=True, null=True)
    cat_logo = models.CharField(max_length=255, blank=True, null=True)
    user_count = models.IntegerField(blank=True, null=True)
    cat_used = models.IntegerField(blank=True, null=True)
    status = models.BooleanField(default=True)
    yes_service = models.BooleanField(default=False)
    yes_shop = models.BooleanField(default=False)

    class Meta:
        managed = False
        db_table = 'cat'
    def __str__(self):
        return self.name


class Comment(models.Model):
    com_id = models.AutoField(primary_key=True)
    com_text = models.CharField(max_length=255)
    com_like = models.IntegerField()
    com_dislike = models.IntegerField()
    com_time = models.DateTimeField()
    com_user = models.ForeignKey('Users', models.DO_NOTHING)
    post = models.ForeignKey('Post', models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'comment'


class DjangoAdminLog(models.Model):
    action_time = models.DateTimeField()
    object_id = models.TextField(blank=True, null=True)
    object_repr = models.CharField(max_length=200)
    action_flag = models.PositiveSmallIntegerField()
    change_message = models.TextField()
    content_type = models.ForeignKey('DjangoContentType', models.DO_NOTHING, blank=True, null=True)
    user = models.ForeignKey(AuthUser, models.DO_NOTHING)

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


class FbPage(models.Model):
    page_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=255)
    cat = models.CharField(max_length=255)
    phone = models.IntegerField()
    link = models.CharField(max_length=255)
    location = models.CharField(max_length=255)
    time = models.DateTimeField(auto_now=True)

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


class MembersMember(models.Model):
    id = models.BigAutoField(primary_key=True)
    firstname = models.CharField(max_length=255)
    lastname = models.CharField(max_length=255)

    class Meta:
        managed = False
        db_table = 'members_member'


class Post(models.Model):
    post_id = models.AutoField(primary_key=True)
    cat = models.ForeignKey(Cat, models.DO_NOTHING)
    user = models.ForeignKey('Users', models.DO_NOTHING)
    post_des = models.CharField(max_length=355)
    post_media = models.CharField(max_length=355)
    post_liked = models.IntegerField()
    post_viewed = models.IntegerField()
    post_shared = models.IntegerField()
    post_time = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'post'


class Reg(models.Model):
    reg_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=255)
    phone = models.CharField(max_length=11)
    password = models.CharField(max_length=100)
    created_date = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'reg'


class Service(models.Model):
    service_id = models.AutoField(primary_key=True)
    cat = models.ForeignKey(Cat, models.DO_NOTHING)
    name = models.CharField(max_length=255)
    location = models.CharField(max_length=255)
    description = models.CharField(max_length=255)
    photo = models.CharField(max_length=255)
    phone = models.IntegerField()
    user = models.ForeignKey('Users', models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'service'


class Shop(models.Model):
    shop_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=255)
    cat = models.ForeignKey(Cat, models.DO_NOTHING)
    location = models.CharField(max_length=255)
    description = models.CharField(max_length=255)
    phone = models.IntegerField()
    photo = models.CharField(max_length=255)
    date_time = models.DateTimeField()
    user = models.ForeignKey('Users', models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'shop'


class TermPolicy(models.Model):
    term_id = models.AutoField(primary_key=True)
    des = models.TextField()

    class Meta:
        managed = False
        db_table = 'term_policy'


class Users(models.Model):
    user_id = models.AutoField(primary_key=True)
    reg = models.ForeignKey(Reg, models.DO_NOTHING)
    cat = models.ForeignKey(Cat, models.DO_NOTHING)
    name = models.TextField()
    phone = models.CharField(max_length=255)
    description = models.CharField(max_length=255)
    location = models.TextField()
    photo = models.CharField(max_length=255)
    user_type = models.BooleanField(max_length=255,default=False)
    status = models.BooleanField(default=True)
    user_shared = models.IntegerField()
    user_viewed = models.IntegerField()
    user_called = models.IntegerField()
    user_total_post = models.IntegerField()
    user_logged_date = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'users'


class ViewList(models.Model):
    view_id = models.AutoField(primary_key=True)
    view_time = models.DateTimeField()
    view_user_id = models.IntegerField()
    user_id = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'view_list'
