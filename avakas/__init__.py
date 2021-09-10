"""
avakas main load
"""

from avakas import flavors
from avakas.errors import AvakasError
from avakas.avakas import Avakas, register_flavor

__all__ = [
    'Avakas',
    'AvakasError',
    'register_flavor',
    'flavors',
]
