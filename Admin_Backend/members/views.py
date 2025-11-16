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
from django.contrib.auth import authenticate
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.utils import timezone
from django.db.models import Count,Q, F, OuterRef, Subquery, IntegerField, Value,Sum
from datetime import timedelta, datetime
from django.db.models.functions import TruncDate,TruncMonth,Coalesce
from rest_framework import status






@api_view(['POST'])
def login_superuser(request):
    username = request.data.get('username')
    password = request.data.get('password')

    user = authenticate(username=username, password=password)

    if user is not None and user.is_superuser:
        return Response({
            'success': True,
            'message': 'Login successful',
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'is_superuser': user.is_superuser,
                'is_staff': user.is_staff,
            }
        })
    else:
        return Response({
            'success': False,
            'message': 'Invalid credentials or not a superuser'
        })



# def data_view(request):
#     data = list(Users.objects.values())
#     return JsonResponse({'data': data})

def str_to_bool(val):
    return val.lower() in ('true', '1', 'yes','True','False')
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
        is_service = str_to_bool(request.POST.get('yes_service'.lower(), 'false'))
        is_shop = str_to_bool(request.POST.get('yes_shop'.lower(), 'false'))
        
       
        if is_service == 'True' and is_shop == 'False':
            is_service = 1
            is_shop = 0
        
        if is_service == 'False' and is_shop == 'True':
            is_service = 0
            is_shop = 1
        
            
        print(is_service)   
        print(is_shop)
        

        if not (cat_name and cat_logo):
            return JsonResponse({"error": "cat_name,cat_logo,is_service,is_shop are required!"}, status=400)

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
            cat = Cat(cat_name=cat_name, cat_logo=file_name,yes_service=is_service,yes_shop=is_shop)
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
                    address=address,
                    visit_count=0
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
                    link = web,
                    visit_count = 0

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

# @csrf_exempt
# def user_type_toggle_status(request, pk):
   
#     if request.method == "POST":
#         user = get_object_or_404(Users, pk=pk)
       
#         user.user_type = not user.user_type
#         user.save()
#         return JsonResponse({
#             "success": True,
#             "message": "User type updated successfully.",
#             "id": user.user_id,
#             "name": user.name,
#             "status": user.user_type
#         }, status=200)
#     return JsonResponse({"error": "Invalid request method."}, status=400)

@csrf_exempt
def user_type_toggle_status(request, pk):
    if request.method == "POST":
        user = get_object_or_404(Users, pk=pk)

        # Toggle between 'PAID' and 'FREE'
        if user.user_type and user.user_type.upper() == "PAID":
            user.user_type = "FREE"
        else:
            user.user_type = "PAID"

        user.save(update_fields=["user_type"])

        return JsonResponse({
            "success": True,
            "message": "User type updated successfully.",
            "id": user.user_id,
            "name": user.name,
            # Send boolean to Flutter (True = PAID, False = FREE)
            "user_type": True if user.user_type == "PAID" else False
        }, status=200)

    return JsonResponse({"error": "Invalid request method."}, status=400)



# def get_users(request):
#     """
#     API to fetch, search, and sort Users data based on different criteria.
#     Query parameters:
#         - sort: Defines the sorting method ('recent', 'category', 'user_type', 'user_called').
#         - category: (Optional) Filter users by a specific category ID.
#         - user_type: (Optional) Filter by user_type ('free' or 'paid').
#         - search: (Optional) Search for a user by user_id. Returns specific user data if provided.
#     """
#     if request.method == 'GET':
#         sort_by = request.GET.get('sort', 'recent')
#         category = request.GET.get('category', None)
#         user_type = request.GET.get('user_type', None)
#         search = request.GET.get('search', None)  # Search by user_id
#         user_id = request.GET.get('search', None)
#         download = request.GET.get('download', None) 

#         users = Users.objects.all()
#         cats = Cat.objects.all()
#         print(type(cats))


#         if search:
#             users = users.filter(user_id=search)

#         # Filter by category
#         if category:
#             users = users.filter(cat_id=category)

#         # Filter by user_type
#         if user_type:
#             users = users.filter(user_type=user_type)
        
#          #Query users
#         if user_id:  # Fetch a specific user
#             users = Users.objects.filter(user_id=user_id)
            
#             if not users.exists():
#                 return JsonResponse({'error': 'User not found'}, status=404)
#         else:  # Fetch all users
#             users = Users.objects.all()
        
#         user_data = list(users.select_related('cat_id').values(
#         'user_id', 'name', 'phone', 'description', 'location', 'photo',
#         'user_type', 'status', 'user_shared', 'user_viewed', 'user_called',
#         'user_total_post', 'user_logged_date', 'cat_id',
#         'cat__cat_name'  # <-- Fetch cat_name from related Cat model
#         ))

#         for u in user_data:
#             if isinstance(u['user_type'], str):
#                 u['user_type'] = True if u['user_type'].lower() == 'paid' else False
       
#         # Sort by criteria
#         if sort_by == 'recent':
#             users = users.order_by('-user_logged_date')  # Most recent
#         elif sort_by == 'category':
#             users = users.order_by('cat_id')  # Sorted by category ID
#         elif sort_by == 'paid':
#             users = users.filter(user_type__iexact='PAID')
#         elif sort_by == 'free':
#             users = users.filter(user_type__iexact='FREE')
#         elif sort_by == 'user_called':
#             users = users.order_by('-user_called')  # Highest to lowest calls
#         else:
#             return JsonResponse({'error': 'Invalid sort parameter'}, status=400)

#         # Format response for multiple users
       
#         user_data = list(users.select_related('cat').values(
#                 'user_id', 'name', 'phone', 'description', 'location', 'photo',
#                 'user_type', 'status', 'user_shared', 'user_viewed', 'user_called',
#                 'user_total_post', 'user_logged_date', 'cat_id',
#                 'cat_id__cat_name'  # <-- Fetch cat_name from related Cat model
#             ))
        
        

#         return JsonResponse({'users': user_data}, status=200, safe=False)

#     return JsonResponse({'error': 'Invalid request method'}, status=405)


def get_users(request):
    """
    API to fetch, search, and sort Users data based on different criteria.
    Query parameters:
        - sort: Defines the sorting method ('recent', 'category', 'paid', 'free', 'user_called').
        - category: (Optional) Filter users by a specific category ID.
        - user_type: (Optional) Filter by user_type ('PAID' or 'FREE').
        - search: (Optional) Search for a user by user_id.
    """
    if request.method == 'GET':
        sort_by = request.GET.get('sort', 'recent')
        category = request.GET.get('category', None)
        user_type = request.GET.get('user_type', None)
        search = request.GET.get('search', None)

        users = Users.objects.all()

        # Search by user_id
        if search:
            users = users.filter(user_id=search)
            if not users.exists():
                return JsonResponse({'error': 'User not found'}, status=404)

        # Filter by category
        if category:
            users = users.filter(cat_id=category)

        # Filter by user_type (capital string in DB)
        if user_type:
            users = users.filter(user_type__iexact=user_type.upper())

        # Sorting
        if sort_by == 'recent':
            users = users.order_by('-user_logged_date')
        elif sort_by == 'category':
            users = users.order_by('cat_id')
        elif sort_by == 'paid':
            users = users.filter(user_type__iexact='PAID')
        elif sort_by == 'free':
            users = users.filter(user_type__iexact='FREE')
        elif sort_by == 'user_called':
            users = users.order_by('-user_called')
        else:
            return JsonResponse({'error': 'Invalid sort parameter'}, status=400)

        # Prepare response data
        user_data = list(users.select_related('cat').values(
            'user_id', 'name', 'phone', 'description', 'location', 'photo',
            'user_type', 'status', 'user_shared', 'user_viewed', 'user_called',
            'user_total_post', 'user_logged_date', 'cat_id',
            'cat__cat_name'
        ))

        # Convert PAID/FREE -> boolean for Flutter
        for u in user_data:
            if isinstance(u['user_type'], str):
                u['user_type'] = True if u['user_type'].upper() == 'PAID' else False

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





@api_view(['GET'])
def dashboard_stats(request):
    today_start = datetime.combine(now().date(), datetime.min.time()).replace(tzinfo=timezone.utc)
    today_end = datetime.combine(now().date(), datetime.max.time()).replace(tzinfo=timezone.utc)

    last7_start = today_start - timedelta(days=7)
    last30_start = today_start - timedelta(days=30)

    # Registrations grouped by day (last 30 days) – ORM version (তুমি চাইলে বাদ দিতে পারো)
    reg_counts = (
        Reg.objects.filter(created_date__range=(last30_start, today_end))
        .extra(select={'day': "DATE(created_date)"})
        .values('day')
        .annotate(count=Count('reg_id'))
        .order_by('day')
    )
    reg_counts_day = (
    Reg.objects
    .annotate(day=TruncDate('created_date', tzinfo=None))  # timezone conversion বন্ধ
    .values('day')
    .annotate(count=Count('reg_id'))
    .order_by('-day')
)
    registrations_day = [
    {"day": row["day"].isoformat(), "count": row["count"]}
    for row in reg_counts_day
]

    # Month-wise registrations 
    reg_counts_month = (
        Reg.objects
        .annotate(month=TruncMonth('created_date', tzinfo=None))  # timezone conversion বন্ধ
        .values('month')
        .annotate(count=Count('reg_id'))
        .order_by('-month')
    )
    
    registrations_month = [
    {"month": row["month"].strftime("%Y-%m"), "count": row["count"]}
    for row in reg_counts_month
]


    # Posts today and last 7/30 days
    today_posts = Post.objects.filter(post_time__range=(today_start, today_end)).count()
    last7_posts = Post.objects.filter(post_time__gte=last7_start).count()
    last30_posts = Post.objects.filter(post_time__gte=last30_start).count()

    # User logins today, last 7/30 days
    today_logins = Users.objects.filter(user_logged_date__range=(today_start, today_end)).count()
    last7_logins = Users.objects.filter(user_logged_date__gte=last7_start).count()
    last30_logins = Users.objects.filter(user_logged_date__gte=last30_start).count()

    return Response({
        "registrations": list(reg_counts),      # ORM last30 days
        "registrations_day": registrations_day,           # Raw SQL all days
        "registrations_month": registrations_month,       # Raw SQL all months
        "today_posts": today_posts,
        "last7_posts": last7_posts,
        "last30_posts": last30_posts,
        "today_logins": today_logins,
        "last7_logins": last7_logins,
        "last30_logins": last30_logins,
    })



def deactivated_users(request):
    """
    GET /api/deactivated-users/?sort=most_recent|most_called|most_viewed
       &user_id=123
       &service_id=456
       &name=partial
       &mobile=017...
    Returns JSON: { total: int, results: [ ... ] }
    """

    # শুধুমাত্র যাদের deactivated_at NOT NULL
    qs = Users.objects.filter(deactivated_at__isnull=False)

    # সর্বশেষ deactivation reason/time আনতে Subquery
    deact_qs = UserDeactivations.objects.filter(
        user_id=OuterRef('user_id'),
        deactivated_at=OuterRef('deactivated_at')  # 👈 match করতে হবে users.deactivated_at এর সাথে
    ).order_by('-deactivated_at')

    # Search filters
    user_id = request.GET.get('user_id')
    service_id_param = request.GET.get('service_id')
    name = request.GET.get('name')
    mobile = request.GET.get('mobile')

    if user_id:
        qs = qs.filter(user_id=user_id)
    if name:
        qs = qs.filter(name__icontains=name)
    if mobile:
        qs = qs.filter(phone__icontains=mobile)

    # Category name
    cat_name_sq = Cat.objects.filter(pk=OuterRef('cat_id')).values('cat_name')[:1]

    # Service/shop IDs
    service_sq = Service.objects.filter(user_id=OuterRef('user_id')).values('service_id')[:1]
    shop_sq = Shop.objects.filter(user_id=OuterRef('user_id')).values('shop_id')[:1]

    qs = qs.annotate(
        deactivation_reason=Subquery(deact_qs.values('reason')[:1]),
        deactivation_time=Subquery(deact_qs.values('deactivated_at')[:1]),
        cat_name=Subquery(cat_name_sq),
        service_id_annotated=Coalesce(Subquery(service_sq, output_field=IntegerField()), Value(0)),
        shop_id_annotated=Coalesce(Subquery(shop_sq, output_field=IntegerField()), Value(0)),
    )

    # Sorting
    sort = request.GET.get('sort', 'most_recent')
    if sort == 'most_called':
        qs = qs.order_by(F('user_called').desc(nulls_last=True))
    elif sort == 'most_viewed':
        qs = qs.order_by(F('user_viewed').desc(nulls_last=True))
    else:
        qs = qs.order_by(F('deactivation_time').desc(nulls_last=True))

    total = qs.count()

    results = []
    for u in qs[:200]:
        if u.cat_id == 56:
            service_id_val = 0
            shop_id_val = 0
        else:
            service_id_val = getattr(u, 'service_id_annotated', 0) or 0
            shop_id_val = getattr(u, 'shop_id_annotated', 0) or 0

        user_type = 'paid' if u.is_active else 'unpaid'

        results.append({
            'user_id': u.user_id,
            'name': u.name,
            'phone': u.phone,
            'email': u.email,
            'category_name': getattr(u, 'cat_name', '') or '',
            'user_type': user_type,
            'status': bool(u.status),
            'is_active': bool(u.is_active),
            'call_status': u.call_status or '',
            'user_called': u.user_called,
            'user_viewed': u.user_viewed,
            'user_total_post': u.user_total_post,
            'deactivated_at': u.deactivated_at,  # 👈 users table থেকে
            'deactivation_reason': getattr(u, 'deactivation_reason', '') or '',
            'service_id': service_id_val,
            'shop_id': shop_id_val,
        })

    return JsonResponse({'total': total, 'results': results}, safe=False)


@api_view(['GET'])
def referral_list(request):
    sort = request.GET.get('sort', 'most_recent')
    search_user_id = request.GET.get('user_id')
    search_name = request.GET.get('name')
    search_phone = request.GET.get('phone')
    # search_mobile = request.GET.get('mobile')

    qs = UserReferrals.objects.all()

    # Search filter
    if search_user_id:
        qs = qs.filter(referrer_user_id=search_user_id)
    if search_name:
        qs = qs.filter(referrer_user_id__in=Users.objects.filter(name__icontains=search_name).values_list('user_id', flat=True))
    if search_phone:
        qs = qs.filter(referrer_user_id__in=Users.objects.filter(phone__icontains=search_phone).values_list('user_id', flat=True))
    # if search_mobile:
    #     qs = qs.filter(referred_user_id__in=Users.objects.filter(phone__icontains=search_mobile).values_list('user_id', flat=True))

    # Sorting
    if sort == 'most_recent':
        qs = qs.order_by('-created_at')
    elif sort == 'highest_points':
        qs = qs.order_by('-points')
    elif sort == 'paid':
        qs = qs.filter(payment_status='paid').order_by('-created_at')
    elif sort == 'unpaid':
        qs = qs.filter(payment_status='unpaid').order_by('-created_at')

    serializer = UserReferralSerializer(qs, many=True)

    # Summary counts
    summary = {
        "total": qs.count(),
        "verified": qs.filter(verification='verified').count(),
        "unverified": qs.filter(verification='unverified').count(),
        "waiting": qs.filter(verification='waiting').count(),
        "paid": qs.filter(payment_status='paid').count(),
        "unpaid": qs.filter(payment_status='unpaid').count(),
    }

    return Response({
        "summary": summary,
        "results": serializer.data
    })

@api_view(['PATCH'])
def update_referral(request, pk):
    try:
        referral = UserReferrals.objects.get(pk=pk)
    except UserReferrals.DoesNotExist:
        return Response({"error": "Referral not found"}, status=status.HTTP_404_NOT_FOUND)

    verification = request.data.get("verification")
    payment_status = request.data.get("payment_status")

    # Verification update
    if verification:
        referral.verification = verification

    # Payment update
    if payment_status:
        if payment_status == "paid":
            referral.payment_status = "paid"
            referral.paid_at = timezone.now()
           
        elif payment_status == "unpaid":
            referral.payment_status = "unpaid"
            referral.paid_at = None

    referral.save()

    return Response({
        "message": "Referral updated successfully",
        "id": referral.id,
        "payment_status": referral.payment_status,
        "paid_at": referral.paid_at,
        "verification": referral.verification
    })
