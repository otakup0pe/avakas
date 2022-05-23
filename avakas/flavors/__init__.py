"""
Avakas Built-In Project Flavors
"""

from .base import AvakasLegacy
from .ansible import AvakasAnsibleProject
from .chef import AvakasChefProject
from .git import AvakasGitNative
from .node import AvakasNodeProject

__all__ = [
    'AvakasAnsibleProject',
    'AvakasChefProject',
    'AvakasGitNative',
    'AvakasLegacy',
    'AvakasNodeProject',
]
