class EnsureJsonCharsetMiddleware:
    """DRF/Django JSON responses omit ';charset=utf-8' (valid per RFC 8259 —
    JSON is always UTF-8), but Dart's http package falls back to latin1 when
    no charset is declared, mojibake-ing any Bangla text or emoji. Declaring
    the charset explicitly fixes this for every endpoint at once."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        content_type = response.get('Content-Type', '')
        if content_type.startswith('application/json') and 'charset' not in content_type:
            response['Content-Type'] = content_type + '; charset=utf-8'
        return response
