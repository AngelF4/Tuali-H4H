from slowapi import Limiter
from slowapi.util import get_remote_address

# Limiter global — se usa como decorador en cada endpoint
limiter = Limiter(key_func=get_remote_address)