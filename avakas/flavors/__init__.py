"""
Avakas Built-In Project Flavors
"""

from .base import AvakasLegacy
from .ansible import AvakasAnsibleProject
from .chef import AvakasChefProject
from .erlang import AvakasErlangProject
from .node import AvakasNodeProject

__all__ = [
    'AvakasLegacy',
    'AvakasAnsibleProject',
    'AvakasChefProject',
    'AvakasErlangProject',
    'AvakasNodeProject',
]
