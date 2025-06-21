import os
from MySQLdb import Time
from django.views import View
from rest_framework.views import APIView
from rest_framework.generics import ListCreateAPIView
from rest_framework.response import Response
from .models import *  
from .serializers import *
import pandas as pd
import time

from django.http import JsonResponse,HttpResponse
from django.template.loader import render_to_string
from django.views.decorators.csrf import csrf_exempt
from ftplib import FTP
from django.core.files.storage import FileSystemStorage
from openpyxl import load_workbook
from datetime import datetime
from django.shortcuts import get_object_or_404
from weasyprint import HTML
import tempfile
from unicodedata import normalize


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
def upload_hotline_numbers_excel(request):
    if request.method != "POST":
        return JsonResponse({"error": "Only POST requests are allowed"}, status=405)

    if "file" not in request.FILES:
        return JsonResponse({"error": "No file provided"}, status=400)

    file = request.FILES["file"]

    try:
        # Save uploaded Excel file temporarily
        fs = FileSystemStorage()
        filename = fs.save(file.name, file)
        filepath = fs.path(filename)

        # Read Excel sheet named "data"
        data = pd.read_excel(filepath, sheet_name='hotlines')

        # Loop through each row in the Excel sheet
        for index, row in data.iterrows():
    
            raw_name = row.get("name", "")
            name = str(raw_name).strip() if pd.notnull(raw_name) else ""

            # Handle phone
            raw_phone = row.get("phone", "")
            if pd.notnull(raw_phone):
                if isinstance(raw_phone, float):
                    phone = str(int(raw_phone)).strip()
                else:
                    phone = str(raw_phone).strip()
            else:
                phone = ""

            # Handle category
            category = str(row.get("category", "")).strip() if pd.notnull(row.get("category", "")) else ""

            # Handle photo
            photo = str(row.get("photo", "")).strip() if pd.notnull(row.get("photo", "")) else ""

            # Skip if essential fields are empty
            if not name or not phone or not category:
                continue

            # Insert after checking duplicates
            if not HotlineNumbers.objects.filter(name=name, phone=phone).exists():
                HotlineNumbers.objects.create(
                    name=name,
                    phone=phone,
                    category=category,
                    photo=photo
                )


        # Delete the uploaded temp file
        fs.delete(filename)

        return JsonResponse({"message": "Hotline numbers uploaded successfully"}, status=201)

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


#Insert useful app links from excel file
@csrf_exempt
def apps_links_excel(request):
    if request.method != "POST":
        return JsonResponse({"error": "Only POST requests are allowed"}, status=405)

    if "file" not in request.FILES:
        return JsonResponse({"error": "No file provided"}, status=400)

    file = request.FILES["file"]

    try:
        fs = FileSystemStorage()
        filename = fs.save(file.name, file)
        filepath = fs.path(filename)

        data = pd.read_excel(filepath, sheet_name='apps')

        for index, row in data.iterrows():
            name = str(row.get("name", "")).strip().lower() if pd.notnull(row.get("name", "")) else ""
            web = str(row.get("web", "")).strip().lower() if pd.notnull(row.get("web", "")) else ""
            address = str(row.get("address", "")).strip().lower() if pd.notnull(row.get("address", "")) else ""
            category = str(row.get("category", "")).strip().lower() if pd.notnull(row.get("category", "")) else ""
            photo = str(row.get("photo", "")).strip().lower() if pd.notnull(row.get("photo", "")) else ""

            if not name or not web or not category:
                continue

            if not Apps.objects.filter(name__iexact=name, web__iexact=web).exists():
                Apps.objects.create(
                    name=name,
                    web=web,
                    category=category,
                    photo=photo,
                    address=address
                )

        fs.delete(filename)
        return JsonResponse({"message": "Apps are uploaded successfully"}, status=201)

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# insert fb_page page from excel file 

@csrf_exempt
def fb_page_excel(request):
    if request.method != "POST":
        return JsonResponse({"error": "Only POST requests are allowed"}, status=405)

    if "file" not in request.FILES:
        return JsonResponse({"error": "No file provided"}, status=400)

    file = request.FILES["file"]

    try:
        # Save uploaded Excel file temporarily
        fs = FileSystemStorage()
        filename = fs.save(file.name, file)
        filepath = fs.path(filename)

        # Read Excel sheet named "data"
        data = pd.read_excel(filepath, sheet_name='fb_page')

        # Loop through each row in the Excel sheet
        for index, row in data.iterrows():
    
            # raw_name = row.get("name", "")
            name = str(row.get("name", "")).strip() if pd.notnull(name) else ""

            # Handle phone
            # raw_web = row.get("web", "")
            web = str(row.get("web","")).strip() if pd.notnull(web) else ""
            # raw_address = row.get("web", "")
            address = str(row.get("address", "")).strip() if pd.notnull(address) else ""

            raw_phone = row.get("phone", "")
            if pd.notnull(raw_phone):
                if isinstance(raw_phone, float):
                    phone = "0"+str(int(raw_phone)).strip()
                else:
                    phone = "0"+str(raw_phone).strip()
            else:
                phone = ""
            # if pd.notnull(raw_web):
            #     if isinstance(raw_web, float):
            #         phone = str(int(raw_web)).strip()
            #     else:
            #         phone = str(raw_web).strip()
            # else:
            #     phone = ""

            # Handle category
            category = str(row.get("category", "")).strip() if pd.notnull(row.get("category", "")) else ""

            # Handle photo
            # photo = str(row.get("photo", "")).strip() if pd.notnull(row.get("photo", "")) else ""

            # Skip if essential fields are empty
            if not name or not web or not category or not phone:
                continue

            # Insert after checking duplicates
            if not FbPage.objects.filter(name=name, web=web).exists():
                Apps.objects.create(
                    name = name,
                    cat = category,
                    phone = phone,
                    location = address,
                    link = web

                )


        # Delete the uploaded temp file
        fs.delete(filename)

        return JsonResponse({"message": "fb pages are uploaded successfully"}, status=201)

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


@csrf_exempt
def user_toggle_status(request, pk):
    
    if request.method == "POST":
        user = get_object_or_404(Users, pk=pk)
        # Toggle status (1 becomes 0 and 0 becomes 1)
        user.status = not user.status
        user.save()

        return JsonResponse({
            "success": True,
            "message": "User status updated successfully.",
            "id": user.user_id,
            "name": user.name,
            "status": user.status
        }, status=200)
    return JsonResponse({"error": "Invalid request method."}, status=400)

@csrf_exempt
def user_type_toggle_status(request, pk):
   
    if request.method == "POST":
        user = get_object_or_404(Users, pk=pk)
        # Toggle status (1 becomes 0 and 0 becomes 1)
        user.user_type = not user.user_type
        user.save()
        return JsonResponse({
            "success": True,
            "message": "User type updated successfully.",
            "id": user.user_id,
            "name": user.name,
            "status": user.user_type
        }, status=200)
    return JsonResponse({"error": "Invalid request method."}, status=400)



def get_users(request):
    """
    API to fetch, search, and sort Users data based on different criteria.
    Query parameters:
        - sort: Defines the sorting method ('recent', 'category', 'user_type', 'user_called').
        - category: (Optional) Filter users by a specific category ID.
        - user_type: (Optional) Filter by user_type ('free' or 'paid').
        - search: (Optional) Search for a user by user_id. Returns specific user data if provided.
    """
    if request.method == 'GET':
        sort_by = request.GET.get('sort', 'recent')
        category = request.GET.get('category', None)
        user_type = request.GET.get('user_type', None)
        search = request.GET.get('search', None)  # Search by user_id
        user_id = request.GET.get('search', None)
        download = request.GET.get('download', None) 

        users = Users.objects.all()


        if search:
            users = users.filter(user_id=search)

        # Filter by category
        if category:
            users = users.filter(cat_id=category)

        # Filter by user_type
        if user_type:
            users = users.filter(user_type=user_type)
        
         #Query users
        if user_id:  # Fetch a specific user
            users = Users.objects.filter(user_id=user_id)
            if not users.exists():
                return JsonResponse({'error': 'User not found'}, status=404)
        else:  # Fetch all users
            users = Users.objects.all()
        
        user_data = list(users.values(
            'user_id', 'name', 'phone', 'description', 'location', 'photo',
            'user_type', 'status', 'user_shared', 'user_viewed', 'user_called',
            'user_total_post', 'user_logged_date', 'cat_id'
        ))

        # if download:  # Generate a PDF if the 'download' parameter is set
        #     # Render data in HTML template for PDF
        #     if user_id:
        #         if user_id:  # Fetch specific user based on user_id
        #             try:
        #                 user = Users.objects.get(user_id=user_id)  # Fetch a specific user
        #             except Users.DoesNotExist:
        #                 return JsonResponse({'error': 'User not found'}, status=404)
                    
        #             # Convert user to a dictionary to pass into the template
        #             user_data = {
        #                 'user_id': user.user_id,
        #                 'name': user.name,
        #                 'phone': user.phone,
        #                 'user_type': user.user_type,
        #                 'status': user.status,
        #                 'location': user.location,
        #                 'user_total_post': user.user_total_post,
        #                 'user_logged_date': user.user_logged_date,
        #             }
        #         # Only one user if filtering by user_id
        #         data = user_data
        #         user_name = data['name'].replace(" ", "_")  # To safely use in the filename
        #         filename = f"{user_name}.pdf"  # Dynamic filename based on user name
        #     else:
        #         filename = "user_data.pdf"
            
        #     template_path = os.path.join(os.getcwd(), "templates", "user_template.html")
        #     if not os.path.exists(template_path):
        #         raise FileNotFoundError("HTML template not found at {}".format(template_path))

        #     html_content = render_to_string('user_template.html', {'users': data})
            
        #     # Create a temporary PDF file
        #     pdf_file = tempfile.NamedTemporaryFile(delete=False, suffix=".pdf")
        #     HTML(string=html_content).write_pdf(pdf_file.name)

        #     # Read the temporary file content and return it as a response
        #     with open(pdf_file.name, 'rb') as f:
        #         pdf_content = f.read()

        #     # Delete the temporary file after use
        #     pdf_file.close()

        #     # Return the file as a downloadable attachment
        #     # Return the PDF file as response for download with specific filename
        #     response = HttpResponse(pdf_content, content_type='application/pdf')
        #     response['Content-Disposition'] = f'attachment; filename="{filename}"'
        #     return response
       

        # Sort by criteria
        if sort_by == 'recent':
            users = users.order_by('-user_logged_date')  # Most recent
        elif sort_by == 'category':
            users = users.order_by('cat_id')  # Sorted by category ID
        elif sort_by == 'paid':
            users = users.filter(user_type=True)
        elif sort_by == 'free':
            users = users.filter(user_type=False)  # Sorted by user type
        elif sort_by == 'user_called':
            users = users.order_by('-user_called')  # Highest to lowest calls
        else:
            return JsonResponse({'error': 'Invalid sort parameter'}, status=400)

        # Format response for multiple users
        user_data = list(users.values(
            'user_id', 'name', 'phone', 'description', 'location', 'photo',
            'user_type', 'status', 'user_shared', 'user_viewed', 'user_called',
            'user_total_post', 'user_logged_date', 'cat_id'
        ))

        return JsonResponse({'users': user_data}, status=200, safe=False)

    return JsonResponse({'error': 'Invalid request method'}, status=405)




def download_user(request):
    """
    API to fetch and download a specific user's data as a PDF.
    Query parameter:
        - user_id: The ID of the user whose data needs to be downloaded.
    """
    if request.method == 'GET':
        seconds = time.time()
        now = time.ctime(seconds)
        user_id = request.GET.get('user_id', None)

        if not user_id:
            return JsonResponse({'error': 'User ID is required'}, status=400)

        try:
            user = Users.objects.get(user_id=user_id)
        except Users.DoesNotExist:
            return JsonResponse({'error': 'User not found'}, status=404)

        user_data = {
            'user_id': user.user_id,
            'name': user.name,
            'phone': user.phone,
            'user_type': user.user_type,
            'status': user.status,
            'location': user.location,
            'user_total_post': user.user_total_post,
            'user_logged_date': user.user_logged_date,
            'now': now,  # Include generated time
        }

        try:
            template_path = os.path.join(os.getcwd(), "templates", "user_template.html")
            if not os.path.exists(template_path):
                raise FileNotFoundError("HTML template not found at {}".format(template_path))

            html_content = render_to_string('user_template.html', {'user': user_data})

            pdf_file = tempfile.NamedTemporaryFile(delete=False, suffix=".pdf")
            HTML(string=html_content).write_pdf(pdf_file.name)

            with open(pdf_file.name, 'rb') as f:
                pdf_content = f.read()

            pdf_file.close()

            user_name = user.name.replace(" ", "_")
            pdf_filename = f"{user_name}.pdf"

            response = HttpResponse(pdf_content, content_type='application/pdf')
            response['Content-Disposition'] = f'attachment; filename="{pdf_filename}"'
            return response

        except Exception as e:
            return JsonResponse({'error': f'Error generating PDF: {str(e)}'}, status=500)

    return JsonResponse({'error': 'Invalid request method'}, status=405)
