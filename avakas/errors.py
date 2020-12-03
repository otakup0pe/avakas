"""
Avakas Errors
"""


class AvakasError(Exception):
    """
    Basic Avakas Error
    """
    def __init__(self, message):
        self.message = message
        super().__init__()
