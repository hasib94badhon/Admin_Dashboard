from rest_framework import serializers
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
