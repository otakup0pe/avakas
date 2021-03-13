"""
Avakas Built-In Project Flavors
"""

from .base import AvakasLegacy
from .ansible import AvakasAnsibleProject
from .chef import AvakasChefProject
from .erlang import AvakasErlangProject
from .git import AvakasGitNative
from .node import AvakasNodeProject

__all__ = [
    'AvakasAnsibleProject',
    'AvakasChefProject',
    'AvakasErlangProject',
    'AvakasGitNative',
    'AvakasLegacy',
    'AvakasNodeProject',
]
