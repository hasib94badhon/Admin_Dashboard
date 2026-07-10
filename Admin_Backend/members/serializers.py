from rest_framework import serializers
from django.utils import timezone
from .models import *


class UserModelSerializer(serializers.ModelSerializer):
    class Meta:
        model = Users  # Reference to your model
        fields = '__all__'     # Include all fields from the model
        # Alternatively, use:
        # fields = ['field1', 'field2', 'field3']


class CatModelSerializer(serializers.ModelSerializer):
    class Meta:
        model = Cat  # Reference to your model
        fields = '__all__'     # Include all fields from the model
        # Alternatively, use:
        # fields = ['field1', 'field2', 'field3']


class LocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Location
        fields = ['address', 'updated_at']

class UserSerializer(serializers.ModelSerializer):
    location_info = serializers.SerializerMethodField()
    cat_name = serializers.CharField(source='cat.cat_name', read_only=True)

    class Meta:
        model = Users
        fields = ['user_id', 'name', 'phone', 'self_referral_id', 'location_info','cat_name','is_active','user_type']

    def get_location_info(self, obj):
        try:
            loc = Location.objects.get(user_id=obj.user_id)
            return {
                "address": loc.address,
                "updated_at": loc.updated_at
            }
        except Location.DoesNotExist:
            return None

class UserReferralSerializer(serializers.ModelSerializer):
    referrer = serializers.SerializerMethodField()
    referred = serializers.SerializerMethodField()

    class Meta:
        model = UserReferrals
        fields = [
            'id', 'referral_id', 'points', 'payment_status',
            'created_at', 'verification', 'referrer', 'referred','paid_at'
        ]

    def get_referrer(self, obj):
        try:
            user = Users.objects.get(user_id=obj.referrer_user_id)
            return UserSerializer(user).data
        except Users.DoesNotExist:
            return None

    def get_referred(self, obj):
        try:
            user = Users.objects.get(user_id=obj.referred_user_id)
            return UserSerializer(user).data
        except Users.DoesNotExist:
            return None


class ServiceUserSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user_id.name', read_only=True)
    cat_name = serializers.CharField(source='cat_id.cat_name', read_only=True)
    phone = serializers.CharField(source='user_id.phone', read_only=True)
    photo = serializers.CharField(source='user_id.photo', read_only=True)
    subscriber_type = serializers.SerializerMethodField()
    last_pay = serializers.SerializerMethodField()
    location_address = serializers.SerializerMethodField()
    location_updated_at = serializers.SerializerMethodField()

    class Meta:
        model = Service
        fields = [
            'user_id', 'service_id', 'name', 'date_time',
            'user_name', 'cat_name', 'phone', 'photo',
            'subscriber_type', 'last_pay',
            'location_address', 'location_updated_at'
        ]

    def get_subscriber_type(self, obj):
        sub = Subscribers.objects.filter(user_id=obj.user_id.user_id).first()
        return sub.type if sub else "N/A"

    def get_last_pay(self, obj):
        sub = Subscribers.objects.filter(user_id=obj.user_id.user_id).first()
        return sub.last_pay if sub and sub.last_pay else "N/A"

    def get_location_address(self, obj):
        loc = Location.objects.filter(user_id=obj.user_id.user_id).first()
        return loc.address if loc else "N/A"

    def get_location_updated_at(self, obj):
        loc = Location.objects.filter(user_id=obj.user_id.user_id).first()
        return loc.updated_at if loc else "N/A"


class ShopUserSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user_id.name', read_only=True)
    cat_name = serializers.CharField(source='cat_id.cat_name', read_only=True)
    phone = serializers.CharField(source='user_id.phone', read_only=True)
    photo = serializers.CharField(source='user_id.photo', read_only=True)
    subscriber_type = serializers.SerializerMethodField()
    last_pay = serializers.SerializerMethodField()
    location_address = serializers.SerializerMethodField()
    location_updated_at = serializers.SerializerMethodField()

    class Meta:
        model = Shop
        fields = [
            'user_id', 'shop_id', 'name', 'date_time',
            'user_name', 'cat_name', 'phone', 'photo',
            'subscriber_type', 'last_pay',
            'location_address', 'location_updated_at'
        ]

    def get_subscriber_type(self, obj):
        sub = Subscribers.objects.filter(user_id=obj.user_id.user_id).first()
        return sub.type if sub else "N/A"

    def get_last_pay(self, obj):
        sub = Subscribers.objects.filter(user_id=obj.user_id.user_id).first()
        return sub.last_pay if sub and sub.last_pay else "N/A"

    def get_location_address(self, obj):
        loc = Location.objects.filter(user_id=obj.user_id.user_id).first()
        return loc.address if loc else "N/A"

    def get_location_updated_at(self, obj):
        loc = Location.objects.filter(user_id=obj.user_id.user_id).first()
        return loc.updated_at if loc else "N/A"



MONTHLY_CALL_THRESHOLD = 10
MONTHLY_VIEW_THRESHOLD = 20


class SubscriberSerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()
    phone = serializers.SerializerMethodField()
    category = serializers.SerializerMethodField()
    service_id = serializers.SerializerMethodField()
    shop_id = serializers.SerializerMethodField()
    location_address = serializers.SerializerMethodField()
    last_pay = serializers.SerializerMethodField()
    user_status = serializers.SerializerMethodField()
    monthly_calls = serializers.SerializerMethodField()
    monthly_views = serializers.SerializerMethodField()
    eligible_for_notification = serializers.SerializerMethodField()

    class Meta:
        model = Subscribers
        fields = [
            "sub_id", "user_id", "user_name", "phone", "category",
            "service_id", "shop_id", "type", "requested_at", "last_notified_at",
            "last_pay", "payment_history", "location_address", "user_status",
            "monthly_calls", "monthly_views", "eligible_for_notification",
        ]

    def get_user_name(self, obj):
        user = Users.objects.filter(user_id=obj.user_id).first()
        return user.name if user else None

    def get_phone(self, obj):
        user = Users.objects.filter(user_id=obj.user_id).first()
        return user.phone if user else None

    def get_category(self, obj):
        cat = Cat.objects.filter(cat_id=obj.cat_id).first()
        return cat.cat_name if cat else 'N/A'

    def get_service_id(self, obj):
        service = Service.objects.filter(user_id=obj.user_id).first()
        return service.service_id if service else "N/A"

    def get_shop_id(self, obj):
        shop = Shop.objects.filter(user_id=obj.user_id).first()
        return shop.shop_id if shop else "N/A"

    def get_location_address(self, obj):
        loc = Location.objects.filter(user_id=obj.user_id).first()
        return loc.address if loc else 'N/A'

    def get_last_pay(self, obj):
        return obj.last_pay if obj.last_pay else 'N/A'

    def get_user_status(self, obj):
        user = Users.objects.filter(user_id=obj.user_id).first()
        return bool(user.status and user.is_active) if user else False

    def _month_start(self):
        n = timezone.localtime(timezone.now())
        return n.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    def get_monthly_calls(self, obj):
        return CallList.objects.filter(
            user_id=obj.user_id, call_time__gte=self._month_start()
        ).count()

    def get_monthly_views(self, obj):
        return ViewList.objects.filter(
            user_id=obj.user_id, view_time__gte=self._month_start()
        ).count()

    def get_eligible_for_notification(self, obj):
        calls = self.get_monthly_calls(obj)
        views = self.get_monthly_views(obj)
        crosses_threshold = calls >= MONTHLY_CALL_THRESHOLD or views >= MONTHLY_VIEW_THRESHOLD
        if not crosses_threshold:
            return False
        if obj.last_notified_at and obj.last_notified_at >= self._month_start():
            return False
        return True


# Add new subscribers
class SubscriberSerializerPost(serializers.ModelSerializer):
    class Meta:
        model = Subscribers
        fields = "__all__"