"""
Business Summary endpoint for the admin panel's "Summary" tab.

GET /api/summary-stats/          (page key: 'summary')
GET /api/summary-stats/?fresh=1  (skip the 2-minute cache)

Everything here is read-only and computed with raw SQL against the shared
app database (the same tables Flask writes to), so dates follow MySQL's
NOW()/CURDATE() -- the same clock Flask uses when it writes rows.

How the AaramBD lead model maps onto the tables
-----------------------------------------------
  supply   users (profile category) + service / shop listings
  leads    call_list  (caller -> provider)  and  view_list (viewer -> provider)
           users.user_called / users.user_viewed are the running totals
  qualify  a provider whose user_called > call_threshold or
           user_viewed > view_threshold (subscription_settings) gets a row in
           subscribers (type 'unpaid') and a one-time push notice
  revenue  subscribers.type = 'paid'  x  cat.subscription_fee
  growth   user_referrals (data collectors' onboarding, points, payouts)

Note: call_list / view_list keep ONE row per (customer, provider) pair and
overwrite the time with the latest contact, so the daily trend counts
"customer-provider pairs last active that day", not individual calls.
"""
import datetime
import logging

from django.core.cache import cache
from django.db import connection
from rest_framework.decorators import api_view
from rest_framework.response import Response

from .permissions import page_access

CACHE_KEY = 'summary_stats_v1'
CACHE_SECONDS = 120
TREND_DAYS = 30


def _rows(cursor, sql, params=None):
    cursor.execute(sql, params or [])
    cols = [c[0] for c in cursor.description]
    return [dict(zip(cols, r)) for r in cursor.fetchall()]


def _one(cursor, sql, params=None):
    rows = _rows(cursor, sql, params)
    return rows[0] if rows else {}


def _int(v):
    try:
        return int(v or 0)
    except (TypeError, ValueError):
        return 0


def _pct(part, whole):
    return round(100.0 * part / whole, 1) if whole else 0.0


def _thresholds(cursor):
    row = _one(cursor, "SELECT call_threshold, view_threshold FROM subscription_settings WHERE id = 1")
    return _int(row.get('call_threshold')) or 50, _int(row.get('view_threshold')) or 100


def _kpis(cursor, call_t, view_t):
    u = _one(cursor, """
        SELECT
          COUNT(*)                                                        AS total_users,
          SUM(CASE WHEN status = 1 AND is_active = 1 THEN 1 ELSE 0 END)  AS active_users,
          SUM(CASE WHEN user_logged_date >= NOW() - INTERVAL 7 DAY  THEN 1 ELSE 0 END) AS wau,
          SUM(CASE WHEN user_logged_date >= NOW() - INTERVAL 30 DAY THEN 1 ELSE 0 END) AS mau,
          SUM(IFNULL(user_called, 0))                                     AS total_calls,
          SUM(IFNULL(user_viewed, 0))                                     AS total_views,
          SUM(CASE WHEN IFNULL(user_called,0) > %s OR IFNULL(user_viewed,0) > %s
                   THEN 1 ELSE 0 END)                                     AS qualified
        FROM users
    """, [call_t, view_t])

    new_users = _one(cursor, """
        SELECT
          SUM(CASE WHEN created_date >= NOW() - INTERVAL 30 DAY THEN 1 ELSE 0 END) AS last30,
          SUM(CASE WHEN created_date >= NOW() - INTERVAL 60 DAY
                    AND created_date <  NOW() - INTERVAL 30 DAY THEN 1 ELSE 0 END) AS prev30
        FROM reg
    """)

    listings = _one(cursor, """
        SELECT
          (SELECT COUNT(*) FROM service)                                                  AS services,
          (SELECT COUNT(*) FROM shop)                                                     AS shops,
          (SELECT COUNT(*) FROM service WHERE date_time >= NOW() - INTERVAL 30 DAY)       AS services_30d,
          (SELECT COUNT(*) FROM shop    WHERE date_time >= NOW() - INTERVAL 30 DAY)       AS shops_30d,
          (SELECT COUNT(*) FROM (SELECT user_id FROM service UNION SELECT user_id FROM shop) p) AS providers
    """)

    leads = _one(cursor, """
        SELECT
          (SELECT COUNT(*) FROM call_list WHERE call_time >= NOW() - INTERVAL 30 DAY) AS call_pairs_30d,
          (SELECT COUNT(*) FROM call_list WHERE call_time >= NOW() - INTERVAL 60 DAY
                                           AND call_time <  NOW() - INTERVAL 30 DAY) AS call_pairs_prev30,
          (SELECT COUNT(*) FROM view_list WHERE view_time >= NOW() - INTERVAL 30 DAY) AS view_pairs_30d,
          (SELECT COUNT(DISTINCT call_user_id) FROM call_list
                                     WHERE call_time >= NOW() - INTERVAL 30 DAY)      AS customers_called_30d
    """)

    subs = _one(cursor, """
        SELECT
          SUM(CASE WHEN LOWER(s.type) = 'paid' THEN 1 ELSE 0 END)                    AS paid,
          SUM(CASE WHEN LOWER(s.type) <> 'paid' THEN 1 ELSE 0 END)                   AS unpaid,
          SUM(CASE WHEN LOWER(s.type) = 'paid' THEN IFNULL(c.subscription_fee,0) ELSE 0 END) AS paid_value
        FROM subscribers s
        LEFT JOIN cat c ON c.cat_id = s.cat_id
    """)

    # Providers who crossed a threshold but are not paying = money on the table.
    potential = _one(cursor, """
        SELECT COUNT(*) AS cnt, SUM(IFNULL(c.subscription_fee, 0)) AS value
        FROM users u
        LEFT JOIN cat c         ON c.cat_id = u.cat_id
        LEFT JOIN subscribers s ON s.user_id = u.user_id
        WHERE (IFNULL(u.user_called,0) > %s OR IFNULL(u.user_viewed,0) > %s)
          AND (s.type IS NULL OR LOWER(s.type) <> 'paid')
    """, [call_t, view_t])

    qualified = _int(u.get('qualified'))
    paid = _int(subs.get('paid'))
    providers = _int(listings.get('providers'))
    call_pairs = _int(leads.get('call_pairs_30d'))
    active = _int(u.get('active_users'))

    return {
        'total_users': _int(u.get('total_users')),
        'active_users': _int(u.get('active_users')),
        'weekly_active': _int(u.get('wau')),
        'monthly_active': _int(u.get('mau')),
        'new_users_30d': _int(new_users.get('last30')),
        'new_users_prev30': _int(new_users.get('prev30')),
        'service_listings': _int(listings.get('services')),
        'shop_listings': _int(listings.get('shops')),
        'new_listings_30d': _int(listings.get('services_30d')) + _int(listings.get('shops_30d')),
        'providers': providers,
        'total_calls': _int(u.get('total_calls')),
        'total_views': _int(u.get('total_views')),
        'call_leads_30d': call_pairs,
        'call_leads_prev30': _int(leads.get('call_pairs_prev30')),
        'view_leads_30d': _int(leads.get('view_pairs_30d')),
        'customers_called_30d': _int(leads.get('customers_called_30d')),
        'call_leads_per_active_profile_30d': round(call_pairs / active, 2) if active else 0.0,
        'qualified_providers': qualified,
        'paid_subscribers': paid,
        'unpaid_subscribers': _int(subs.get('unpaid')),
        'paid_subscription_value': _int(subs.get('paid_value')),
        'unpaid_qualified': _int(potential.get('cnt')),
        'uncollected_value': _int(potential.get('value')),
        'qualified_to_paid_pct': _pct(paid, qualified),
        'call_threshold': call_t,
        'view_threshold': view_t,
    }


def _funnel(cursor, call_t, view_t):
    # Every stage is a subset of the one before: all counted among active,
    # non-blocked profiles only.
    r = _one(cursor, """
        SELECT
          COUNT(*)                                                                    AS active_profiles,
          SUM(CASE WHEN IFNULL(u.user_called,0) + IFNULL(u.user_viewed,0) > 0
                   THEN 1 ELSE 0 END)                                                AS got_leads,
          SUM(CASE WHEN IFNULL(u.user_called,0) > %s OR IFNULL(u.user_viewed,0) > %s
                   THEN 1 ELSE 0 END)                                                AS qualified,
          SUM(CASE WHEN (IFNULL(u.user_called,0) > %s OR IFNULL(u.user_viewed,0) > %s)
                    AND s.last_notified_at IS NOT NULL THEN 1 ELSE 0 END)             AS notified,
          SUM(CASE WHEN LOWER(s.type) = 'paid' THEN 1 ELSE 0 END)                     AS paid
        FROM users u
        LEFT JOIN subscribers s ON s.user_id = u.user_id
        WHERE u.status = 1 AND u.is_active = 1
    """, [call_t, view_t, call_t, view_t])
    return [
        {'stage': 'Active profiles', 'count': _int(r.get('active_profiles'))},
        {'stage': 'Received a lead', 'count': _int(r.get('got_leads'))},
        {'stage': 'Crossed threshold', 'count': _int(r.get('qualified'))},
        {'stage': 'Subscription notice sent', 'count': _int(r.get('notified'))},
        {'stage': 'Paid subscriber', 'count': _int(r.get('paid'))},
    ]


def _daily(cursor, table, col, days):
    rows = _rows(cursor, f"""
        SELECT DATE({col}) AS d, COUNT(*) AS n FROM {table}
        WHERE {col} >= CURDATE() - INTERVAL %s DAY
        GROUP BY DATE({col})
    """, [days - 1])
    out = {}
    for r in rows:
        d = r['d']
        if isinstance(d, datetime.datetime):
            d = d.date()
        if isinstance(d, str):
            d = datetime.date.fromisoformat(d[:10])
        out[d] = _int(r['n'])
    return out


def _trend(cursor):
    today_row = _one(cursor, "SELECT CURDATE() AS t")
    today = today_row.get('t') or datetime.date.today()
    if isinstance(today, str):
        today = datetime.date.fromisoformat(today[:10])
    series = {
        'registrations': _daily(cursor, 'reg', 'created_date', TREND_DAYS),
        'call_leads': _daily(cursor, 'call_list', 'call_time', TREND_DAYS),
        'view_leads': _daily(cursor, 'view_list', 'view_time', TREND_DAYS),
        'services': _daily(cursor, 'service', 'date_time', TREND_DAYS),
        'shops': _daily(cursor, 'shop', 'date_time', TREND_DAYS),
    }
    days = [today - datetime.timedelta(days=i) for i in range(TREND_DAYS - 1, -1, -1)]
    return [
        {
            'date': d.isoformat(),
            'registrations': series['registrations'].get(d, 0),
            'call_leads': series['call_leads'].get(d, 0),
            'view_leads': series['view_leads'].get(d, 0),
            'new_listings': series['services'].get(d, 0) + series['shops'].get(d, 0),
        }
        for d in days
    ]


def _categories(cursor, call_t, view_t):
    rows = _rows(cursor, """
        SELECT
          c.cat_id, c.cat_name, IFNULL(c.subscription_fee, 0) AS fee,
          COUNT(u.user_id)                                    AS users,
          SUM(IFNULL(u.user_called, 0))                       AS calls,
          SUM(IFNULL(u.user_viewed, 0))                       AS views,
          SUM(CASE WHEN IFNULL(u.user_called,0) > %s OR IFNULL(u.user_viewed,0) > %s
                   THEN 1 ELSE 0 END)                         AS qualified,
          SUM(CASE WHEN LOWER(s.type) = 'paid' THEN 1 ELSE 0 END) AS paid
        FROM cat c
        JOIN users u            ON u.cat_id = c.cat_id
        LEFT JOIN subscribers s ON s.user_id = u.user_id
        GROUP BY c.cat_id, c.cat_name, c.subscription_fee
        HAVING SUM(IFNULL(u.user_called, 0)) + SUM(IFNULL(u.user_viewed, 0)) > 0
        ORDER BY SUM(IFNULL(u.user_called, 0)) DESC, SUM(IFNULL(u.user_viewed, 0)) DESC
        LIMIT 15
    """, [call_t, view_t])
    listings = {r['cat_id']: _int(r['n']) for r in _rows(cursor, """
        SELECT cat_id, COUNT(*) AS n FROM (
            SELECT cat_id FROM service UNION ALL SELECT cat_id FROM shop
        ) x GROUP BY cat_id
    """)}
    out = []
    for r in rows:
        users = _int(r['users'])
        calls = _int(r['calls'])
        qualified = _int(r['qualified'])
        paid = _int(r['paid'])
        fee = _int(r['fee'])
        out.append({
            'cat_id': r['cat_id'],
            'name': r['cat_name'] or f"#{r['cat_id']}",
            'users': users,
            'listings': listings.get(r['cat_id'], 0),
            'calls': calls,
            'views': _int(r['views']),
            'calls_per_user': round(calls / users, 1) if users else 0.0,
            'qualified': qualified,
            'paid': paid,
            'fee': fee,
            'uncollected_value': max(qualified - paid, 0) * fee,
        })
    return out


def _data_quality(cursor):
    r = _one(cursor, """
        SELECT
          COUNT(*) AS total,
          SUM(CASE WHEN photo IS NULL OR TRIM(photo) = '' THEN 1 ELSE 0 END)             AS no_photo,
          SUM(CASE WHEN location IS NULL OR TRIM(location) = '' THEN 1 ELSE 0 END)       AS no_location,
          SUM(CASE WHEN description IS NULL OR TRIM(description) = '' THEN 1 ELSE 0 END) AS no_description,
          SUM(CASE WHEN cat_id IS NULL OR cat_id = 0 THEN 1 ELSE 0 END)                  AS no_category,
          SUM(CASE WHEN user_logged_date IS NULL
                    OR user_logged_date < NOW() - INTERVAL 30 DAY THEN 1 ELSE 0 END)     AS dormant_30d,
          SUM(CASE WHEN status = 0 THEN 1 ELSE 0 END)                                    AS blocked,
          SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END)                                 AS deactivated
        FROM users
    """)
    dead = _one(cursor, """
        SELECT COUNT(*) AS n FROM users u
        WHERE u.user_id IN (SELECT user_id FROM service UNION SELECT user_id FROM shop)
          AND IFNULL(u.user_called, 0) = 0 AND IFNULL(u.user_viewed, 0) = 0
    """)
    orphans = _one(cursor, """
        SELECT
          (SELECT COUNT(*) FROM service s LEFT JOIN users u ON u.user_id = s.user_id
            WHERE u.user_id IS NULL) +
          (SELECT COUNT(*) FROM shop s LEFT JOIN users u ON u.user_id = s.user_id
            WHERE u.user_id IS NULL) AS n
    """)
    total = _int(r.get('total'))

    def item(key, label, count, base):
        return {'key': key, 'label': label, 'count': count, 'pct': _pct(count, base)}

    providers = _int(_one(cursor, """
        SELECT COUNT(*) AS n FROM (SELECT user_id FROM service UNION SELECT user_id FROM shop) p
    """).get('n'))
    return {
        'total_users': total,
        'issues': [
            item('no_photo', 'Profiles without photo', _int(r.get('no_photo')), total),
            item('no_location', 'Profiles without location', _int(r.get('no_location')), total),
            item('no_description', 'Profiles without description', _int(r.get('no_description')), total),
            item('no_category', 'Profiles without category', _int(r.get('no_category')), total),
            item('dormant_30d', 'Not opened app in 30 days', _int(r.get('dormant_30d')), total),
            item('blocked', 'Blocked by admin', _int(r.get('blocked')), total),
            item('deactivated', 'Self-deactivated', _int(r.get('deactivated')), total),
            item('dead_listings', 'Listings with zero calls/views', _int(dead.get('n')), providers),
            item('orphan_listings', 'Listings whose owner no longer exists', _int(orphans.get('n')), providers),
        ],
    }


def _collectors(cursor):
    s = _one(cursor, """
        SELECT
          COUNT(*) AS total,
          SUM(CASE WHEN created_at >= NOW() - INTERVAL 30 DAY THEN 1 ELSE 0 END) AS last30,
          SUM(CASE WHEN verification = 'verified'   THEN 1 ELSE 0 END)           AS verified,
          SUM(CASE WHEN verification = 'waiting'    THEN 1 ELSE 0 END)           AS waiting,
          SUM(CASE WHEN verification = 'unverified' THEN 1 ELSE 0 END)           AS unverified,
          SUM(CASE WHEN verification = 'verified' AND payment_status <> 'paid'
                   THEN IFNULL(points, 0) ELSE 0 END)                            AS points_due,
          SUM(CASE WHEN payment_status = 'paid' THEN IFNULL(points, 0) ELSE 0 END) AS points_paid
        FROM user_referrals
    """)
    top = _rows(cursor, """
        SELECT r.referrer_user_id AS user_id, u.name,
               COUNT(*) AS referrals,
               SUM(CASE WHEN r.verification = 'verified' THEN 1 ELSE 0 END) AS verified,
               SUM(CASE WHEN r.verification = 'verified' AND r.payment_status <> 'paid'
                        THEN IFNULL(r.points, 0) ELSE 0 END)               AS points_due
        FROM user_referrals r
        LEFT JOIN users u ON u.user_id = r.referrer_user_id
        WHERE r.created_at >= NOW() - INTERVAL 90 DAY
        GROUP BY r.referrer_user_id, u.name
        ORDER BY referrals DESC
        LIMIT 10
    """)
    total = _int(s.get('total'))
    return {
        'total': total,
        'last_30d': _int(s.get('last30')),
        'verified': _int(s.get('verified')),
        'waiting': _int(s.get('waiting')),
        'unverified': _int(s.get('unverified')),
        'verified_pct': _pct(_int(s.get('verified')), total),
        'points_due': _int(s.get('points_due')),
        'points_paid': _int(s.get('points_paid')),
        'top_collectors_90d': [
            {
                'user_id': t['user_id'],
                'name': t['name'] or f"User #{t['user_id']}",
                'referrals': _int(t['referrals']),
                'verified': _int(t['verified']),
                'points_due': _int(t['points_due']),
            }
            for t in top
        ],
    }


def build_summary():
    with connection.cursor() as cursor:
        call_t, view_t = _thresholds(cursor)
        sections = {}
        for name, fn in (
            ('kpis', lambda: _kpis(cursor, call_t, view_t)),
            ('funnel', lambda: _funnel(cursor, call_t, view_t)),
            ('trend', lambda: _trend(cursor)),
            ('categories', lambda: _categories(cursor, call_t, view_t)),
            ('data_quality', lambda: _data_quality(cursor)),
            ('collectors', lambda: _collectors(cursor)),
        ):
            # One broken section (e.g. a table missing on a dev DB) must not
            # blank the whole page -- report it and keep going.
            try:
                sections[name] = fn()
            except Exception as e:  # noqa: BLE001
                logging.exception('summary section %s failed', name)
                sections[name] = None
                sections.setdefault('errors', {})[name] = str(e)
        with connection.cursor() as c2:
            now_row = _one(c2, "SELECT NOW() AS n")
        sections['generated_at'] = str(now_row.get('n'))
        return sections


@api_view(['GET'])
@page_access('summary')
def summary_stats(request):
    fresh = request.GET.get('fresh') in ('1', 'true', 'yes')
    data = None if fresh else cache.get(CACHE_KEY)
    if data is None:
        data = build_summary()
        cache.set(CACHE_KEY, data, CACHE_SECONDS)
    return Response(data)
