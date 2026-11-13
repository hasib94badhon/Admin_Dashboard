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
