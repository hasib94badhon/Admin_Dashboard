"""Manual token-based auth/permission checks shared by every view in this app.

Roughly half the views here are plain Django functions (JsonResponse,
request.POST/GET), not DRF `@api_view`/APIView -- so DRF's
DEFAULT_AUTHENTICATION_CLASSES/DEFAULT_PERMISSION_CLASSES would silently miss
them. resolve_token_user() works the same way against a raw HttpRequest or a
DRF Request (both expose .META), so the same decorator/permission class can
guard both flavors of view uniformly.
"""
from functools import wraps

from django.http import JsonResponse
from rest_framework.authtoken.models import Token
from rest_framework.permissions import BasePermission

# Mirrors the route set in lib/routing/routes.dart. 'staff_admin' itself is
# never toggled here -- managing other admins is always superuser-only.
PAGE_KEYS = [
    'overview', 'drivers', 'clients', 'insert', 'appstatus',
    'referral', 'deactivation', 'deleted_accounts', 'service', 'shop',
    'subscribers', 'reactions', 'terms', 'contact', 'notifications',
]


def resolve_token_user(request):
    """Look up the requesting user from an `Authorization: Token <key>`
    header. Returns None if the header is missing, the token is invalid, or
    the account has been deactivated."""
    auth_header = request.META.get('HTTP_AUTHORIZATION', '')
    if not auth_header.startswith('Token '):
        return None
    token_key = auth_header.split(' ', 1)[1].strip()
    try:
        token = Token.objects.select_related('user').get(key=token_key)
    except Token.DoesNotExist:
        return None
    if not token.user.is_active:
        return None
    return token.user


def user_has_page(user, page_keys):
    """page_keys may be a single page-key string, or a list/tuple of them
    for endpoints shared across more than one page (e.g. the category
    dropdown on the Subscribers page reuses the Categories/drivers list
    endpoint) -- access is granted if the admin has any one of them."""
    if user.is_superuser:
        return True
    profile = getattr(user, 'admin_profile', None)
    if not profile:
        return False
    keys = (page_keys,) if isinstance(page_keys, str) else page_keys
    return any(k in profile.allowed_pages for k in keys)


def page_access(*page_keys):
    """Decorator for plain Django views and @api_view functions alike.
    Place it as the innermost decorator (directly above `def ...`)."""
    def decorator(view_func):
        @wraps(view_func)
        def wrapped(request, *args, **kwargs):
            user = resolve_token_user(request)
            if user is None:
                return JsonResponse({'success': False, 'message': 'Authentication required'}, status=401)
            if not user_has_page(user, page_keys):
                return JsonResponse({'success': False, 'message': 'Forbidden'}, status=403)
            request.user = user
            return view_func(request, *args, **kwargs)
        return wrapped
    return decorator


def superuser_required(view_func):
    """Decorator for the admin-management function views -- deliberately not
    routed through page_access, so no page toggle can ever grant the ability
    to manage other admin accounts."""
    @wraps(view_func)
    def wrapped(request, *args, **kwargs):
        user = resolve_token_user(request)
        if user is None:
            return JsonResponse({'success': False, 'message': 'Authentication required'}, status=401)
        if not user.is_superuser:
            return JsonResponse({'success': False, 'message': 'Superadmin access required'}, status=403)
        request.user = user
        return view_func(request, *args, **kwargs)
    return wrapped


class HasPageAccess(BasePermission):
    """For class-based DRF views. Set `page_key = '...'` (or a list of page
    keys, for endpoints shared across pages) on the view class."""
    def has_permission(self, request, view):
        user = resolve_token_user(request)
        if user is None:
            return False
        request.user = user
        return user_has_page(user, getattr(view, 'page_key', None) or [])


class IsSuperUser(BasePermission):
    def has_permission(self, request, view):
        user = resolve_token_user(request)
        if user is None:
            return False
        request.user = user
        return user.is_superuser
