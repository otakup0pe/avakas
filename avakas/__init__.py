"""
avakas main load
"""

import avakas.flavors

from .errors import AvakasError
from .avakas import Avakas, register_flavor

__all__ = [
    'Avakas',
    'AvakasError',
    'register_flavor',
    'flavors',
]
