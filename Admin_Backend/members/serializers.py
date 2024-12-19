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