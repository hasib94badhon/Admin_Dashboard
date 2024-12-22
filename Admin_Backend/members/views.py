from django.views import View
from rest_framework.views import APIView
from rest_framework.generics import ListCreateAPIView
from rest_framework.response import Response
from .models import *  
from .serializers import *
import pandas as pd

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from ftplib import FTP
from django.core.files.storage import FileSystemStorage
from openpyxl import load_workbook
from datetime import datetime
from django.shortcuts import get_object_or_404


# def data_view(request):
#     data = list(Users.objects.values())
#     return JsonResponse({'data': data})

class UsersAPIView(APIView):
    def get(self, request):
        users = Users.objects.all()  # Query all products
        serializer = UserModelSerializer(users, many=True)
        return Response(serializer.data)  # Return serialized data

    def post(self, request):
        serializer = UserModelSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)

class UserListCreateView(ListCreateAPIView):
    queryset = Users.objects.all()
    serializer_class = UserModelSerializer


class CatAPIView(APIView):
    def get(self, request):
        cat = Cat.objects.all()  # Query all products
        serializer = CatModelSerializer(cat, many=True)
        return Response(serializer.data)  # Return serialized data

    def post(self, request):
        serializer = CatModelSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)

class CountAPIView(APIView):
    def get(self, request):
        # Count for each model
        user_count = Users.objects.count()
        cat_count = Cat.objects.count()
        post_count = Post.objects.count()

        # Combine counts into a single response
        response_data = {
            "user_count": user_count,
            "cat_count": cat_count,
            "post_count": post_count
        }
        return Response(response_data)

@csrf_exempt
def insert_cat(request):
    if request.method == 'POST':
        cat_name = request.POST.get('cat_name')
        cat_logo = request.FILES.get('cat_logo')

        if not (cat_name and cat_logo):
            return JsonResponse({"error": "cat_name and cat_logo are required!"}, status=400)

        # Save the photo to an FTP server
        ftp_server = '89.117.27.223'
        ftp_username = 'u790304855'
        ftp_password = 'Abra!!@@12'
        ftp_directory = '/domains/aarambd.com/public_html/cat logo'

        file_name = cat_logo.name

        # Connect to FTP server
        ftp = FTP(ftp_server,ftp_username,ftp_password)
        try:
            ftp.connect(ftp_server)
            ftp.login(user=ftp_username, passwd=ftp_password)
            ftp.cwd(ftp_directory)

            # Upload the file
            with cat_logo.file as file:
                ftp.storbinary(f'STOR {file_name}', file)
                print("Upload to the ftp successfully")
            
            # Save data to the database
            cat = Cat(cat_name=cat_name, cat_logo=file_name)
            cat.save()

            ftp.quit()
            return JsonResponse({"success": "Cat inserted successfully!"})
        except Exception as e:
            ftp.quit()
            return JsonResponse({"error": str(e)}, status=500)
    else:
        return JsonResponse({"error": "Invalid request method"}, status=405)


@csrf_exempt
def upload_excel(request):
    if request.method != "POST":
        return JsonResponse({"error": "Only POST requests are allowed"}, status=405)

    if "file" not in request.FILES:
        return JsonResponse({"error": "No file provided"}, status=400)

    file = request.FILES["file"]

    try:
        # Save file temporarily
        fs = FileSystemStorage()
        filename = fs.save(file.name, file)
        filepath = fs.path(filename)

        # Read Excel file
        data = pd.read_excel(filepath, sheet_name="data")
        
        # Process each row in the Excel file
        for index, row in data.iterrows():
            name = row.get("name", "").strip()
            phone = row.get("phone", "")
            cat_id = row.get("cat_id", None)
            location = row.get("location", "").strip()
            photo = row.get("photo", "").strip()

            # Skip if name or phone is missing
            if not name or not phone:
                continue

            # Check if phone exists in Reg table
            reg, created = Reg.objects.get_or_create(phone=phone, defaults={"name": name})
            if created:
                # If new record, set the default password and created_date
                reg.password = "12345"
                reg.save()

            # Find the Cat by ID
            try:
                cat = Cat.objects.get(cat_id=cat_id)
            except Cat.DoesNotExist:
                cat = None

            # Insert data into Users table
            Users.objects.create(
                reg=reg,
                cat=cat,
                name=name,
                phone=phone,
                location=location,
                photo=photo,
                description="",
                user_shared=0,
                user_viewed=0,
                user_called=0,
                user_total_post=0,
                user_logged_date=None
            )

        # Clean up uploaded file
        fs.delete(filename)

        return JsonResponse({"message": "File processed successfully"}, status=201)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
def toggle_status(request, pk):
    """
    Toggle the status of a category.
    :param request: The HTTP request object.
    :param pk: The primary key of the category to toggle status.
    """
    if request.method == "POST":
        category = get_object_or_404(Cat, pk=pk)
        # Toggle status (1 becomes 0 and 0 becomes 1)
        category.status = not category.status
        category.save()

        return JsonResponse({
            "success": True,
            "message": "Category status updated successfully.",
            "id": category.cat_id,
            "name": category.cat_name,
            "status": category.status
        }, status=200)
    return JsonResponse({"error": "Invalid request method."}, status=400)



from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.db.models import Q
from .models import Users

@csrf_exempt
def get_users(request):
    """
    API to fetch and sort Users data based on different criteria.
    Query parameters:
        - sort: Defines the sorting method ('recent', 'category', 'user_type', 'user_called').
        - category: (Optional) Filter users by a specific category ID.
        - user_type: (Optional) Filter by user_type ('free' or 'paid').

    """
    if request.method == 'GET':
        sort_by = request.GET.get('sort', 'recent')
        category = request.GET.get('category', None)
        user_type = request.GET.get('user_type', None)

        users = Users.objects.all()

        # Filter by category
        if category:
            users = users.filter(cat_id=category)

        # Filter by user_type
        if user_type:
            users = users.filter(user_type=user_type)

        # Sort by criteria
        if sort_by == 'recent':
            users = users.order_by('-user_logged_date')  # Most recent
        elif sort_by == 'category':
            users = users.order_by('cat_id')  # Sorted by category ID
        elif sort_by == 'user_type':
            users = users.order_by('user_type')  # Sorted by user type
        elif sort_by == 'user_called':
            users = users.order_by('-user_called')  # Highest to lowest calls
        else:
            return JsonResponse({'error': 'Invalid sort parameter'}, status=400)

        # Format response
        user_data = list(users.values(
            'user_id', 'name', 'phone', 'description', 'location', 'photo',
            'user_type', 'status', 'user_shared', 'user_viewed', 'user_called',
            'user_total_post', 'user_logged_date', 'cat_id'
        ))

        return JsonResponse({'users': user_data}, status=200, safe=False)

    return JsonResponse({'error': 'Invalid request method'}, status=405)
