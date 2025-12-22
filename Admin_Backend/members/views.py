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
import pytz
from django.http import JsonResponse,HttpResponse
from django.template.loader import render_to_string
from django.views.decorators.csrf import csrf_exempt
from ftplib import FTP
from django.core.files.storage import FileSystemStorage
from openpyxl import load_workbook
from django.shortcuts import get_object_or_404
from weasyprint import HTML
import tempfile
from unicodedata import normalize
from django.contrib.auth import authenticate
from rest_framework.decorators import api_view
from django.utils import timezone
from django.utils.timezone import now,localdate
from django.db.models import Count,Q, F, OuterRef, Subquery, IntegerField, Value,Sum,Case, When, Value,Exists
from datetime import timedelta, datetime
from django.db.models.functions import TruncDate,TruncMonth,Coalesce
from rest_framework import status
from rest_framework.pagination import PageNumberPagination


# bd_timezone = pytz.timezone("Asia/Dhaka") 
current_bd_time = timezone.localtime(timezone.now()) + timedelta(hours=6)

def normalize_datetime(dt):
    """
    সব datetime কে naive করে দেয়, যাতে safe comparison করা যায়।
    """
    if not dt:
        return None
    try:
        return timezone.make_naive(dt, timezone.get_current_timezone())
    except Exception:
        return dt


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
        # Base queryset
        cat = Cat.objects.all()

        # Search by cat_name
        search = request.GET.get('search', None)
        if search:
            cat = cat.filter(cat_name__icontains=search)

        # Sort logic
        sort_by = request.GET.get('sort', None)
        if sort_by in ['status', 'yes_service', 'yes_shop']:
            # Boolean fields → filter only 1 (True)
            cat = cat.filter(**{sort_by: 1})
        elif sort_by in ['user_count', 'cat_used']:
            # Integer fields → descending order
            cat = cat.order_by(f'-{sort_by}')

        serializer = CatModelSerializer(cat, many=True)
        return Response(serializer.data)

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
            # location = row.get("location", "").strip()
            # photo = row.get("photo", "").strip()

            # Skip if name or phone is missing
            if not name or not phone:
                continue

            # Check if phone exists in Reg table
            # reg, created = Reg.objects.get_or_create(phone=phone, defaults={"name": name})
            # if created:
            #     # If new record, set the default password and created_date
            #     reg.password = "12345"
            #     reg.secret_number ="1122"
            #     reg.created_date = timezone.now()
            #     reg.save()

            reg, created = Reg.objects.get_or_create(phone='0'+str(phone), defaults={ "name": name, "password": "12345", "secret_number": "1122", "created_date": current_bd_time }) 

            if not created and reg.created_date is None: 
                reg.created_date = current_bd_time
                reg.save()
            # Find the Cat by ID
            try:
                cat = Cat.objects.get(cat_id=cat_id)
            except Cat.DoesNotExist:
                cat = None

            # Insert data into Users table
            Users.objects.create( 
                reg_id=reg.reg_id, 
                cat=cat, name=name, 
                phone='0' + str(phone), 
                location='', 
                photo='', 
                description='', 
                user_type='FREE', 
                status=True, 
                user_shared=0, 
                user_viewed=0, 
                user_called=0, 
                user_total_post=0, 
                user_logged_date=None, 
                call_status='active', 
                nid='', 
                tin='', 
                self_referral_id='', 
                reg_referral_id='', 
                email='', 
                is_active=1, 
                deactivated_at=None )

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
        fs = FileSystemStorage()
        filename = fs.save(file.name, file)
        filepath = fs.path(filename)

        data = pd.read_excel(filepath, sheet_name='fb_page')

        added_count = 0
        skipped_count = 0
        total_rows = len(data)

        for index, row in data.iterrows():
            raw_name = row.get("name", "")
            name = str(raw_name).strip() if pd.notnull(raw_name) else ""

            raw_web = row.get("web", "")
            web = str(raw_web).strip() if pd.notnull(raw_web) else ""

            raw_address = row.get("address", "")
            address = str(raw_address).strip() if pd.notnull(raw_address) else ""

            raw_phone = row.get("phone", "")
            if pd.notnull(raw_phone):
                if isinstance(raw_phone, float):
                    phone = int(raw_phone)
                else:
                    phone = int(str(raw_phone).strip())
            else:
                phone = None

            raw_cat = row.get("category", "")
            category = str(raw_cat).strip() if pd.notnull(raw_cat) else ""

            raw_photo = row.get("photo", "")
            photo = str(raw_photo).strip() if pd.notnull(raw_photo) else ""

            # Essential fields check
            if not name or not web or not category or not phone:
                skipped_count += 1
                continue

            # Insert if not duplicate
            if not FbPage.objects.filter(name=name, link=web).exists():
                FbPage.objects.create(
                    name=name,
                    cat=category,
                    photo=photo,
                    phone=phone,
                    link=web,
                    location=address,
                    # time=timezone.localtime(timezone.now()),
                    visit_count=0
                )
                added_count += 1
            else:
                skipped_count += 1

        fs.delete(filename)

        return JsonResponse({
            "message": "FB pages processed successfully",
            "summary": {
                "total_rows": total_rows,
                "added_count": added_count,
                "skipped_count": skipped_count
            }
        }, status=201)

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)





@api_view(['POST'])
def toggle_status(request, pk):
    category = get_object_or_404(Cat, pk=pk)
    category.status = not category.status
    category.save()
    return Response({
        "success": True,
        "message": "Category status updated successfully.",
        "id": category.cat_id,
        "name": category.cat_name,
        "status": category.status
    })


@api_view(['POST'])
def user_toggle_status(request, pk):
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

@api_view(['POST'])
def user_type_toggle_status(request, pk):
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
            # users = users.filter(user_id=search)
            users = users.filter(
                Q(user_id__icontains=search) |
                Q(phone__icontains=search) |
                Q(name__icontains=search) |
                Q(user_viewed__icontains=search) |
                Q(cat__cat_name__icontains=search)
            )
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





# @api_view(['GET'])
# def dashboard_stats(request):
#     today_start = datetime.combine(now().date(), datetime.min.time()).replace(tzinfo=timezone.utc)
#     today_end = datetime.combine(now().date(), datetime.max.time()).replace(tzinfo=timezone.utc)

#     last7_start = today_start - timedelta(days=7)
#     last30_start = today_start - timedelta(days=30)

#     # Registrations grouped by day (last 30 days) – ORM version (তুমি চাইলে বাদ দিতে পারো)
#     reg_counts = (
#         Reg.objects.filter(created_date__range=(last30_start, today_end))
#         .extra(select={'day': "DATE(created_date)"})
#         .values('day')
#         .annotate(count=Count('reg_id'))
#         .order_by('day')
#     )
#     reg_counts_day = (
#     Reg.objects
#     .annotate(day=TruncDate('created_date', tzinfo=None))  # timezone conversion বন্ধ
#     .values('day')
#     .annotate(count=Count('reg_id'))
#     .order_by('-day')
# )
#     registrations_day = [
#     {"day": row["day"].isoformat(), "count": row["count"]}
#     for row in reg_counts_day
# ]

#     # Month-wise registrations 
#     reg_counts_month = (
#         Reg.objects
#         .annotate(month=TruncMonth('created_date', tzinfo=None))  # timezone conversion বন্ধ
#         .values('month')
#         .annotate(count=Count('reg_id'))
#         .order_by('-month')
#     )
    
#     registrations_month = [
#     {"month": row["month"].strftime("%Y-%m"), "count": row["count"]}
#     for row in reg_counts_month
# ]


#     # Posts today and last 7/30 days
#     today_posts = Post.objects.filter(post_time__range=(today_start, today_end)).count()
#     last7_posts = Post.objects.filter(post_time__gte=last7_start).count()
#     last30_posts = Post.objects.filter(post_time__gte=last30_start).count()

#     # User logins today, last 7/30 days
#     today_logins = Users.objects.filter(user_logged_date__range=(today_start, today_end)).count()
#     last7_logins = Users.objects.filter(user_logged_date__gte=last7_start).count()
#     last30_logins = Users.objects.filter(user_logged_date__gte=last30_start).count()

#     return Response({
#         "registrations": list(reg_counts),      # ORM last30 days
#         "registrations_day": registrations_day,           # Raw SQL all days
#         "registrations_month": registrations_month,       # Raw SQL all months
#         "today_posts": today_posts,
#         "last7_posts": last7_posts,
#         "last30_posts": last30_posts,
#         "today_logins": today_logins,
#         "last7_logins": last7_logins,
#         "last30_logins": last30_logins,
#     })



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


  # 🔎 Pagination
class ServiceUserPagination(PageNumberPagination):
      page_size = 20
      page_size_query_param = 'page_size'
      max_page_size = 100
          

class ServiceUserList(APIView):
    def get(self, request):
        queryset = Service.objects.all().order_by('service_id')

        # 🔎 Search filters
        search = request.GET.get('search')
        location_filter = Location.objects.filter(
        user_id=OuterRef('user_id_id'),
        address__icontains=search
    )
        if search:
            queryset = queryset.filter(
                  Q(name__icontains=search) |
                Q(service_id__icontains=search) |
                Q(user_id__name__icontains=search) |
                Q(user_id__phone__icontains=search) |
                Q(cat_id__cat_name__icontains=search) |
                Exists(location_filter)
            )

        # 🔎 Sorting
        sort_by = request.GET.get('sort')
        if sort_by == 'cat':
            queryset = queryset.order_by('cat_id__cat_name')
        elif sort_by == 'recent':
            queryset = queryset.order_by('-date_time')
        # elif sort_by == 'location':
        #     queryset = queryset.order_by('service.user_location.address')
        elif sort_by == 'location':

            location_subquery = Location.objects.filter(
                user_id=OuterRef('user_id')
            ).values('address')[:1]

            queryset = queryset.annotate(location_address=Subquery(location_subquery))
            queryset = queryset.order_by('location_address')

        elif sort_by == 'subscriber':
            subscriber_subquery = Subscribers.objects.filter(
            user_id=OuterRef('user_id_id')
        ).values('type')[:1]

            queryset = queryset.annotate(subscriber_type=Subquery(subscriber_subquery))

            queryset = queryset.annotate(
            subscriber_order=Case(
                When(subscriber_type='paid', then=Value(0)),
                When(subscriber_type='unpaid', then=Value(1)),
                default=Value(2),
                output_field=IntegerField(),
            )
        ).order_by('subscriber_order')

      

        paginator = ServiceUserPagination()
        result_page = paginator.paginate_queryset(queryset, request)
        serializer = ServiceUserSerializer(result_page, many=True)

        # 🔎 Summary stats
        total_services = queryset.count()
        total_paid = Subscribers.objects.filter(
            type__iexact='paid',
            user_id__in=queryset.values('user_id')
        ).count()
        total_unpaid = Subscribers.objects.filter(
            type__iexact='unpaid',
            user_id__in=queryset.values('user_id')
        ).count()
        total_cat = queryset.values('cat_id').distinct().count()

        summary = {
            "total_services": total_services,
            "total_paid": total_paid,
            "total_unpaid": total_unpaid,
            "total_cat": total_cat
        }

        return paginator.get_paginated_response({
            "summary": summary,
            "results": serializer.data
        })



class ShopUserPagination(PageNumberPagination):
      page_size = 20
      page_size_query_param = 'page_size'
      max_page_size = 100
          

class ShopUserList(APIView):
    def get(self, request):
        queryset = Shop.objects.all().order_by('shop_id')

        # 🔎 Search filters
        search = request.GET.get('search')
        location_filter = Location.objects.filter(
        user_id=OuterRef('user_id_id'),
        address__icontains=search
    )
        if search:
            queryset = queryset.filter(
                  Q(name__icontains=search) |
                Q(shop_id__icontains=search) |
                Q(user_id__name__icontains=search) |
                Q(user_id__phone__icontains=search) |
                Q(cat_id__cat_name__icontains=search) |
                Exists(location_filter)
            )

        # 🔎 Sorting
        sort_by = request.GET.get('sort')
        if sort_by == 'cat':
            queryset = queryset.order_by('cat_id__cat_name')
        elif sort_by == 'recent':
            queryset = queryset.order_by('-date_time')
        # elif sort_by == 'location':
        #     queryset = queryset.order_by('service.user_location.address')
        elif sort_by == 'location':

            location_subquery = Location.objects.filter(
                user_id=OuterRef('user_id')
            ).values('address')[:1]

            queryset = queryset.annotate(location_address=Subquery(location_subquery))
            queryset = queryset.order_by('location_address')

        elif sort_by == 'subscriber':
            subscriber_subquery = Subscribers.objects.filter(
            user_id=OuterRef('user_id_id')
        ).values('type')[:1]

            queryset = queryset.annotate(subscriber_type=Subquery(subscriber_subquery))

            queryset = queryset.annotate(
            subscriber_order=Case(
                When(subscriber_type='paid', then=Value(0)),
                When(subscriber_type='unpaid', then=Value(1)),
                default=Value(2),
                output_field=IntegerField(),
            )
        ).order_by('subscriber_order')

      

        paginator = ShopUserPagination()
        result_page = paginator.paginate_queryset(queryset, request)
        serializer = ShopUserSerializer(result_page, many=True)

        # 🔎 Summary stats
        total_shops = queryset.count()
        total_paid = Subscribers.objects.filter(
            type__iexact='paid',
            user_id__in=queryset.values('user_id')
        ).count()
        total_unpaid = Subscribers.objects.filter(
            type__iexact='unpaid',
            user_id__in=queryset.values('user_id')
        ).count()
        total_cat = queryset.values('cat_id').distinct().count()

        summary = {
            "total_shops": total_shops,
            "total_paid": total_paid,
            "total_unpaid": total_unpaid,
            "total_cat": total_cat
        }

        return paginator.get_paginated_response({
            "summary": summary,
            "results": serializer.data
        })



class SubscriberPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100

class SubscriberListView(APIView):
    def get(self, request):
        queryset = Subscribers.objects.all()

        # 🔎 Search
        search = request.GET.get('search')
        if search:
            queryset = queryset.filter(
                Q(user_id__icontains=search) |
                Q(type__icontains=search) |
                Q(cat_id__in=Cat.objects.filter(cat_name__icontains=search).values_list('cat_id', flat=True)) |
                Q(user_id__in=Users.objects.filter(
                    Q(name__icontains=search) |
                    Q(phone__icontains=search)
                ).values_list('user_id', flat=True)) |
                Q(user_id__in=Service.objects.filter(
                    Q(service_id__icontains=search)
                ).values_list('user_id', flat=True)) |
                Q(user_id__in=Shop.objects.filter(
                    Q(shop_id__icontains=search)
                ).values_list('user_id', flat=True))
            )

        # 🔎 Sort
        sort_by = request.GET.get('sort')
        if sort_by == "recent":
            queryset = queryset.order_by("-last_pay")
        elif sort_by == "type":
            queryset = queryset.order_by("type")
        elif sort_by == "cat":
            queryset = queryset.order_by("cat_id")
        elif sort_by == "service":
            service_user_ids = Service.objects.values_list("user_id", flat=True)
            queryset = queryset.filter(user_id__in=service_user_ids).order_by("user_id")
        elif sort_by == "shop":
            shop_user_ids = Shop.objects.values_list("user_id", flat=True)
            queryset = queryset.filter(user_id__in=shop_user_ids).order_by("user_id")
        # elif sort_by == "service":
        #     queryset = queryset.order_by("user_id")  # service ভিত্তিক
        # elif sort_by == "shop":
        #     queryset = queryset.order_by("user_id")  # shop ভিত্তিক

        # 🔎 Summary হিসাব করা হবে filtered queryset এর উপর
        total_subscribers = queryset.count()

        # Service vs Shop split
        service_users = Service.objects.filter(user_id__in=queryset.values_list("user_id", flat=True))
        shop_users = Shop.objects.filter(user_id__in=queryset.values_list("user_id", flat=True))

        service_user_ids = service_users.values_list("user_id", flat=True)
        shop_user_ids = shop_users.values_list("user_id", flat=True)

        service_paid = queryset.filter(user_id__in=service_user_ids, type__iexact="paid").count()
        service_unpaid = queryset.filter(user_id__in=service_user_ids, type__iexact="unpaid").count()

        shop_paid = queryset.filter(user_id__in=shop_user_ids, type__iexact="paid").count()
        shop_unpaid = queryset.filter(user_id__in=shop_user_ids, type__iexact="unpaid").count()

        total_categories = queryset.values("cat_id").distinct().count()

        summary = {
            "total_subscribers": total_subscribers,
            "service_paid": service_paid,
            "service_unpaid": service_unpaid,
            "shop_paid": shop_paid,
            "shop_unpaid": shop_unpaid,
            "total_categories": total_categories,
        }

        # 🔎 Pagination
        paginator = SubscriberPagination()
        result_page = paginator.paginate_queryset(queryset, request)
        serializer = SubscriberSerializer(result_page, many=True)

        return paginator.get_paginated_response({
            "summary": summary,
            "results": serializer.data
        })
    


class CreateSubscribersView(APIView):
    def post(self, request):
        today = timezone.now()
        ninety_days_ago = timezone.make_naive(today - timedelta(days=90), timezone.get_current_timezone())

        created_subscribers = []
        service_count = 0
        shop_count = 0

        # 🔎 Subscribers এ যাদের আছে তাদের বাদ দাও
        existing_ids = Subscribers.objects.values_list("user_id", flat=True)
        users = Users.objects.exclude(user_id__in=existing_ids)

        for user in users:
            eligible = False
            source_type = None

            # শর্ত ১: called > 50
            if user.user_called and user.user_called > 50:
                eligible = True

            # শর্ত ২: Service/Shop date_time > 90 days
            service = Service.objects.filter(user_id=user.user_id).first()
            shop = Shop.objects.filter(user_id=user.user_id).first()

            # if service and service.date_time < ninety_days_ago:
            #     eligible = True
            #     source_type = "service"
            # if shop and shop.date_time < ninety_days_ago:
            #     eligible = True
            #     source_type = "shop"

            if service and service.date_time:
                service_dt = normalize_datetime(service.date_time)
                if service_dt and service_dt < ninety_days_ago:
                    eligible = True
                    source_type = "service"

            if shop and shop.date_time:
                shop_dt = normalize_datetime(shop.date_time)
                if shop_dt and shop_dt < ninety_days_ago:
                    eligible = True
                    source_type = "shop"


            if eligible:
                subscriber = Subscribers.objects.create(
                    user_id=user.user_id,
                    reg_id=user.reg_id,
                    cat_id=user.cat_id,
                    type="unpaid",  # default type
                    last_pay=None,
                    payment_history=None
                )
                created_subscribers.append(subscriber)

                # ✅ Count service/shop
                if source_type == "service":
                    service_count += 1
                elif source_type == "shop":
                    shop_count += 1

        serializer = SubscriberSerializerPost(created_subscribers, many=True)

        summary = {
            "total_new": len(created_subscribers),
            "service_new": service_count,
            "shop_new": shop_count
        }

        return Response({
            "summary": summary,
            "new_subscribers": serializer.data
        }, status=status.HTTP_201_CREATED)


class TermPolicyAPIView(APIView):
    # here I get and post the data collector instruction
    def get(self, request):
        """
        GET → term_id=2 এর description দেখাবে
        """
        try:
            term = TermPolicy.objects.get(term_id=3)
            return Response({"term_id": term.term_id, "description": term.des}, status=status.HTTP_200_OK)
        except TermPolicy.DoesNotExist:
            return Response({"error": "TermPolicy with id=3 not found"}, status=status.HTTP_404_NOT_FOUND)

    def post(self, request):
        """
        POST → term_id=2 এর description update করবে
        Body: { "description": "new text here" }
        """
        try:
            term = TermPolicy.objects.get(term_id=3)
            new_des = request.data.get("description", None)
            if new_des:
                term.des = new_des
                term.save()
                return Response({"term_id": term.term_id, "description": term.des}, status=status.HTTP_200_OK)
            else:
                return Response({"error": "description field required"}, status=status.HTTP_400_BAD_REQUEST)
        except TermPolicy.DoesNotExist:
            return Response({"error": "TermPolicy with id=3 not found"}, status=status.HTTP_404_NOT_FOUND)



@csrf_exempt
def toggle_subscriber(request, sub_id):
    if request.method != "POST":
        return JsonResponse({"error": "Only POST allowed"}, status=405)

    try:
        subscriber = Subscribers.objects.get(sub_id=sub_id)

        if subscriber.type.lower() == "unpaid":
            # Toggle to paid
            subscriber.type = "paid"

            # একবারই BD time নাও
            bd_tz = pytz.timezone("Asia/Dhaka")
            bd_time = timezone.now().astimezone(bd_tz)

            # last_pay এ datetime save করো
            subscriber.last_pay = bd_time

            # একই bd_time কে string করে payment_history তে prepend করো
            bd_time_str = bd_time.strftime("%Y-%m-%d %H:%M:%S")
            if subscriber.payment_history:
                subscriber.payment_history = f"{bd_time_str}, {subscriber.payment_history}"
            else:
                subscriber.payment_history = bd_time_str

        else:
            # Toggle to unpaid
            subscriber.type = "unpaid"
            subscriber.last_pay = None

        subscriber.save()

        return JsonResponse({
            "sub_id": subscriber.sub_id,
            "type": subscriber.type,
            "last_pay": subscriber.last_pay.strftime("%Y-%m-%d %H:%M:%S") if subscriber.last_pay else None,
            "payment_history": subscriber.payment_history
        }, status=200)

    except Subscribers.DoesNotExist:
        return JsonResponse({"error": "Subscriber not found"}, status=404)
