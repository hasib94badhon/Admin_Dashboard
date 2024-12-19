from django.views import View
from rest_framework.views import APIView
from rest_framework.generics import ListCreateAPIView
from rest_framework.response import Response
from .models import *  
from .serializers import *


from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import os
from ftplib import FTP
from django.core.files.storage import FileSystemStorage
from openpyxl import load_workbook
from datetime import datetime


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


class UploadUsersView(View):
    def options(self, request, *args, **kwargs):
        """Respond to the CORS preflight request."""
        response = JsonResponse({"message": "CORS preflight successful"})
        response["Access-Control-Allow-Origin"] = "*"
        response["Access-Control-Allow-Methods"] = "POST, OPTIONS"
        response["Access-Control-Allow-Headers"] = "Content-Type, X-Requested-With"
        return response
    
    def post(self, request, *args, **kwargs):
        # Check if file is in request
        excel_file = request.FILES.get("file")
        if not excel_file:
            return JsonResponse({"error": "No file uploaded"}, status=400)

        # Save and parse the file
        # fs = FileSystemStorage(location="uploads/")
        # filename = fs.save(excel_file.name, excel_file)
        file = request.FILES['file']
        fs = FileSystemStorage()
        filename = fs.save(file.name, file)

        try:
            # Load and parse Excel file
            workbook = load_workbook(filename)
            sheet = workbook.active

            for row in sheet.iter_rows(min_row=2, values_only=True):  # Skip header row
                name, phone, cat_id, location, photo = row

                # Ensure phone and name are not empty
                if not phone or not name:
                    continue

                # Check if phone exists in reg table
                reg, created = Reg.objects.get_or_create(
                    phone=phone,
                    defaults={
                        "name": name,
                        "password": "12345",  # Default password
                        "created_time": datetime.now()
                    }
                )
                # Insert data into users table
                Users.objects.create(
                    reg=reg,
                    cat_id=cat_id if cat_id else None,
                    name=name,
                    phone=phone,
                    location=location if location else "",
                    photo=photo if photo else ""
                )

            return JsonResponse({"message": "Data inserted successfully"}, status=201)

        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)

        finally:
            fs.delete(filename) 