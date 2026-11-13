"""
Banner Studio endpoints -- data for the visiting-card banners the admin
panel generates for service and shop listings.

All routes are read-only and guarded by the 'banners' page key.

GET /api/banners/categories/?type=service|shop
    Categories that have at least one listing of that type, with counts.

GET /api/banners/listings/?type=service|shop&cat_id=&search=&page=&page_size=
    Listings ready to print on a card: name, category, description,
    location, phone (with the leading 0 restored) and a photo URL.

GET /api/banners/image/?url=<https://aarambd.com/...>
    Fetches an AaramBD-hosted image server-side and returns the bytes, so the
    Flutter web panel can draw it into an exported PNG without the browser's
    cross-origin restrictions. Only aarambd.com hosts are allowed (no open
    proxy), images only, 5 MB max.
"""
import logging
import re
import urllib.error
import urllib.parse
import urllib.request

from django.db import connection
from django.http import HttpResponse, JsonResponse
from rest_framework.decorators import api_view
from rest_framework.response import Response

from .permissions import page_access

UPLOAD_BASE = 'https://aarambd.com/upload/'
CAT_LOGO_BASE = 'https://aarambd.com/cat%20logo/'
ALLOWED_IMAGE_HOSTS = {'aarambd.com', 'www.aarambd.com', 'try.aarambd.com', 'control.aarambd.com'}
MAX_IMAGE_BYTES = 5 * 1024 * 1024

# table, id column -- never built from user input beyond this whitelist
_TYPES = {
    'service': ('service', 'service_id'),
    'shop': ('shop', 'shop_id'),
}


def _rows(cursor, sql, params=None):
    cursor.execute(sql, params or [])
    cols = [c[0] for c in cursor.description]
    return [dict(zip(cols, r)) for r in cursor.fetchall()]


def _listing_type(request):
    t = (request.GET.get('type') or 'service').strip().lower()
    return t if t in _TYPES else None


def _https(url):
    if url.startswith('http://'):
        return 'https://' + url[len('http://'):]
    return url


def _photo_url(raw):
    """users.photo / listing photo -> one absolute https URL, or ''.
    users.photo is a comma-separated list; the first entry is the profile pic."""
    if not raw:
        return ''
    first = str(raw).split(',')[0].strip()
    if not first:
        return ''
    if first.startswith(('http://', 'https://')):
        return _https(first.replace(' ', '%20'))
    return UPLOAD_BASE + urllib.parse.quote(first)


def _cat_logo_url(name):
    return CAT_LOGO_BASE + urllib.parse.quote(name) if name else ''


def _bd_phone(*candidates):
    """First usable Bangladeshi mobile number from the candidates.
    service.phone / shop.phone are INT columns, so 01712345678 is stored as
    1712345678 -- put the 0 back."""
    for c in candidates:
        if c is None:
            continue
        digits = re.sub(r'\D', '', str(c))
        if digits.startswith('880'):
            digits = digits[2:]
        if len(digits) == 10 and digits.startswith('1'):
            digits = '0' + digits
        if len(digits) == 11 and digits.startswith('01'):
            return digits
    for c in candidates:
        if c not in (None, '', 0):
            return str(c)
    return ''


def _clean(text):
    return re.sub(r'\s+', ' ', str(text or '')).strip()


@api_view(['GET'])
@page_access('banners')
def banner_categories(request):
    t = _listing_type(request)
    if t is None:
        return Response({'error': "type must be 'service' or 'shop'"}, status=400)
    table, _ = _TYPES[t]
    with connection.cursor() as cursor:
        rows = _rows(cursor, f"""
            SELECT c.cat_id, c.cat_name, c.cat_logo, COUNT(*) AS listings
            FROM {table} l
            JOIN cat c ON c.cat_id = l.cat_id
            GROUP BY c.cat_id, c.cat_name, c.cat_logo
            ORDER BY c.cat_name
        """)
    return Response({
        'type': t,
        'categories': [
            {
                'cat_id': r['cat_id'],
                'cat_name': r['cat_name'] or f"Category {r['cat_id']}",
                'cat_logo_url': _cat_logo_url(r['cat_logo']),
                'listings': int(r['listings'] or 0),
            }
            for r in rows
        ],
    })


@api_view(['GET'])
@page_access('banners')
def banner_listings(request):
    t = _listing_type(request)
    if t is None:
        return Response({'error': "type must be 'service' or 'shop'"}, status=400)
    table, id_col = _TYPES[t]

    try:
        page = max(1, int(request.GET.get('page', 1)))
        page_size = min(100, max(1, int(request.GET.get('page_size', 30))))
    except ValueError:
        return Response({'error': 'page and page_size must be numbers'}, status=400)

    where, params = [], []
    cat_id = request.GET.get('cat_id')
    if cat_id:
        if not str(cat_id).isdigit():
            return Response({'error': 'cat_id must be a number'}, status=400)
        where.append('l.cat_id = %s')
        params.append(int(cat_id))
    search = _clean(request.GET.get('search'))
    if search:
        like = f'%{search}%'
        where.append('(l.name LIKE %s OR u.name LIKE %s OR u.phone LIKE %s OR l.location LIKE %s)')
        params += [like, like, like, like]
    where_sql = ('WHERE ' + ' AND '.join(where)) if where else ''

    with connection.cursor() as cursor:
        total = _rows(cursor, f"""
            SELECT COUNT(*) AS n FROM {table} l
            LEFT JOIN users u ON u.user_id = l.user_id
            {where_sql}
        """, params)[0]['n']
        rows = _rows(cursor, f"""
            SELECT l.{id_col} AS id, l.name AS listing_name, l.description AS listing_description,
                   l.location AS listing_location, l.phone AS listing_phone, l.photo AS listing_photo,
                   l.cat_id, c.cat_name, c.cat_logo,
                   u.user_id, u.name AS user_name, u.phone AS user_phone, u.photo AS user_photo,
                   u.description AS user_description, u.location AS user_location,
                   loc.address AS gps_address, s.type AS subscriber_type
            FROM {table} l
            LEFT JOIN users u       ON u.user_id = l.user_id
            LEFT JOIN cat c         ON c.cat_id = l.cat_id
            LEFT JOIN location loc  ON loc.user_id = l.user_id
            LEFT JOIN subscribers s ON s.user_id = l.user_id
            {where_sql}
            ORDER BY l.{id_col} DESC
            LIMIT %s OFFSET %s
        """, params + [page_size, (page - 1) * page_size])

    items = []
    for r in rows:
        photo = _photo_url(r['listing_photo']) or _photo_url(r['user_photo'])
        items.append({
            'type': t,
            'id': r['id'],
            'user_id': r['user_id'],
            'name': _clean(r['listing_name']) or _clean(r['user_name']),
            'owner_name': _clean(r['user_name']),
            'cat_id': r['cat_id'],
            'cat_name': _clean(r['cat_name']),
            'cat_logo_url': _cat_logo_url(r['cat_logo']),
            'description': _clean(r['listing_description']) or _clean(r['user_description']),
            'location': _clean(r['listing_location']) or _clean(r['gps_address']) or _clean(r['user_location']),
            'phone': _bd_phone(r['user_phone'], r['listing_phone']),
            'photo_url': photo,
            'has_photo': bool(photo),
            'subscriber_type': (r['subscriber_type'] or '').lower() or None,
        })

    return Response({
        'type': t,
        'page': page,
        'page_size': page_size,
        'total': int(total or 0),
        'results': items,
    })


@api_view(['GET'])
@page_access('banners')
def banner_image(request):
    url = _https((request.GET.get('url') or '').strip())
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != 'https' or (parsed.hostname or '').lower() not in ALLOWED_IMAGE_HOSTS:
        return JsonResponse({'error': 'Only aarambd.com images can be loaded'}, status=400)
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'AaramBD-Admin-BannerStudio'})
        with urllib.request.urlopen(req, timeout=10) as resp:
            ctype = (resp.headers.get('Content-Type') or '').split(';')[0].strip().lower()
            if not ctype.startswith('image/'):
                return JsonResponse({'error': 'Not an image'}, status=415)
            data = resp.read(MAX_IMAGE_BYTES + 1)
            if len(data) > MAX_IMAGE_BYTES:
                return JsonResponse({'error': 'Image is larger than 5 MB'}, status=413)
    except urllib.error.HTTPError as e:
        return JsonResponse({'error': f'Image not found ({e.code})'}, status=404)
    except Exception as e:  # noqa: BLE001
        logging.warning('banner_image fetch failed for %s: %s', url, e)
        return JsonResponse({'error': 'Could not load image'}, status=502)

    response = HttpResponse(data, content_type=ctype)
    response['Cache-Control'] = 'private, max-age=3600'
    return response


# ── Share a banner as a post in the `description` table ────────────────────
#
# Posts are published from the official AaramBD app account, go live
# immediately and send NO push notifications.
#
# .env settings (Django):
#   AARAMBD_OFFICIAL_USER_ID   users.user_id of the official "AaramBD" app account
#   FTP_UPLOAD_DIR             FTP folder served at https://aarambd.com/upload/
#                              (same value as FTP_DIRECTORY in the Flask .env)
#   FTP_HOST / FTP_USER / FTP_PASS  already used for category logos

import datetime as _dt
import io as _io
from ftplib import FTP as _FTP

from decouple import config as _config

MAX_POST_IMAGE_BYTES = 8 * 1024 * 1024
MAX_CAPTION_CHARS = 2000


def _official_account(cursor):
    """Returns (account_dict or None, error message or None)."""
    raw = str(_config('AARAMBD_OFFICIAL_USER_ID', default='')).strip()
    if not raw.isdigit():
        return None, 'AARAMBD_OFFICIAL_USER_ID is not set in the admin backend .env.'
    rows = _rows(cursor, 'SELECT user_id, name, status FROM users WHERE user_id = %s', [int(raw)])
    if not rows:
        return None, f'Official account user_id {raw} does not exist.'
    acc = rows[0]
    if str(acc.get('status')) in ('0', 'False'):
        return None, f'Official account user_id {raw} is blocked (status = 0).'
    return {'user_id': acc['user_id'], 'name': _clean(acc['name']) or 'AaramBD'}, None


@api_view(['GET'])
@page_access('banners')
def banner_topics(request):
    """Topics (des_cat) and sub-categories for the Share dialog, plus the
    account the post will be published from."""
    with connection.cursor() as cursor:
        cats = _rows(cursor, """
            SELECT des_cat_id, des_cat_name, des_cat_status
            FROM des_cat ORDER BY des_cat_id
        """)
        subs = _rows(cursor, """
            SELECT des_sub_cat_id, des_cat_id, name_en, name_bn, emoji, sort_order
            FROM des_sub_cat ORDER BY des_cat_id, sort_order, des_sub_cat_id
        """)
        account, account_error = _official_account(cursor)

    by_cat = {}
    for s in subs:
        by_cat.setdefault(s['des_cat_id'], []).append({
            'des_sub_cat_id': s['des_sub_cat_id'],
            'name_en': _clean(s['name_en']),
            'name_bn': _clean(s['name_bn']),
            'emoji': s['emoji'] or '',
        })
    return Response({
        'account': account,
        'account_error': account_error,
        'topics': [
            {
                'des_cat_id': c['des_cat_id'],
                'des_cat_name': _clean(c['des_cat_name']),
                'active': str(c['des_cat_status']) not in ('0', 'False'),
                'sub_categories': by_cat.get(c['des_cat_id'], []),
            }
            for c in cats
        ],
    })


def _is_png(data):
    return data[:8] == b'\x89PNG\r\n\x1a\n'


@api_view(['POST'])
@page_access('banners')
def banner_post(request):
    """multipart/form-data:
        image           PNG exported from Banner Studio (required)
        des_cat_id      topic (required)
        des_sub_cat_id  sub-category (optional, must belong to the topic)
        des             caption / post text (optional)
        listing_type    'service' | 'shop'   (for the file name and log)
        listing_id      listing id           (for the file name and log)
    """
    image = request.FILES.get('image')
    if image is None:
        return Response({'success': False, 'message': 'Banner image is missing.'}, status=400)
    if image.size > MAX_POST_IMAGE_BYTES:
        return Response({'success': False, 'message': 'Banner image is larger than 8 MB.'}, status=400)
    data = image.read()
    if not _is_png(data):
        return Response({'success': False, 'message': 'Banner image must be a PNG.'}, status=400)

    des_cat_id = str(request.data.get('des_cat_id') or '').strip()
    des_sub_cat_id = str(request.data.get('des_sub_cat_id') or '').strip()
    caption = str(request.data.get('des') or '').strip()
    listing_type = str(request.data.get('listing_type') or '').strip().lower()
    listing_id = str(request.data.get('listing_id') or '').strip()

    if not des_cat_id.isdigit():
        return Response({'success': False, 'message': 'Choose a topic.'}, status=400)
    if des_sub_cat_id and not des_sub_cat_id.isdigit():
        return Response({'success': False, 'message': 'Invalid sub-category.'}, status=400)
    if len(caption) > MAX_CAPTION_CHARS:
        return Response({'success': False,
                         'message': f'Caption is longer than {MAX_CAPTION_CHARS} characters.'}, status=400)
    if listing_type not in _TYPES:
        listing_type = 'banner'
    if not listing_id.isdigit():
        listing_id = '0'

    with connection.cursor() as cursor:
        if not _rows(cursor, 'SELECT 1 AS ok FROM des_cat WHERE des_cat_id = %s', [int(des_cat_id)]):
            return Response({'success': False, 'message': 'Topic not found.'}, status=400)
        if des_sub_cat_id and not _rows(
                cursor, 'SELECT 1 AS ok FROM des_sub_cat WHERE des_sub_cat_id = %s AND des_cat_id = %s',
                [int(des_sub_cat_id), int(des_cat_id)]):
            return Response({'success': False,
                             'message': 'That sub-category does not belong to the chosen topic.'}, status=400)
        account, account_error = _official_account(cursor)
        if account is None:
            return Response({'success': False, 'message': account_error}, status=409)

    # 1) Upload the PNG to the same folder Flask uses for post photos.
    stamp = _dt.datetime.now().strftime('%Y%m%d%H%M%S')
    filename = f'banner_{listing_type}_{listing_id}_{stamp}.png'
    upload_dir = _config('FTP_UPLOAD_DIR', default='/domains/aarambd.com/public_html/upload')
    try:
        with _FTP(_config('FTP_HOST'), timeout=30) as ftp:
            ftp.login(user=_config('FTP_USER'), passwd=_config('FTP_PASS'))
            ftp.cwd(upload_dir)
            ftp.storbinary(f'STOR {filename}', _io.BytesIO(data))
    except Exception as e:  # noqa: BLE001
        logging.error('banner_post FTP upload failed: %s', e)
        return Response({'success': False, 'message': f'Image upload failed: {e}'}, status=502)
    photo_url = UPLOAD_BASE + filename

    # 2) Insert the post exactly like the app does: live, visible, no notification.
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                INSERT INTO description
                    (user_id, time, des, des_cat_id, des_sub_cat_id, des_photo,
                     des_view, des_com, status, special_note, is_hidden)
                VALUES (%s, NOW(), %s, %s, %s, %s, 0, 0, 'live', '', 0)
            """, [account['user_id'], caption, int(des_cat_id),
                  int(des_sub_cat_id) if des_sub_cat_id else None, photo_url])
            des_id = cursor.lastrowid
    except Exception as e:  # noqa: BLE001
        logging.error('banner_post insert failed (uploaded %s): %s', filename, e)
        return Response({'success': False, 'message': f'Saving the post failed: {e}'}, status=500)

    admin = getattr(request, 'user', None)
    logging.info('[BannerPost] des_id=%s by admin=%s listing=%s:%s topic=%s/%s photo=%s',
                 des_id, getattr(admin, 'username', '?'), listing_type, listing_id,
                 des_cat_id, des_sub_cat_id or '-', photo_url)

    return Response({
        'success': True,
        'message': 'Posted',
        'des_id': des_id,
        'photo_url': photo_url,
        'posted_as': account,
    }, status=201)
