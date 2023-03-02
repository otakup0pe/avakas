"""
Avakas Built-In Project Flavors
"""

from avakas.flavors.base import AvakasLegacy
from avakas.flavors.ansible import AvakasAnsibleProject
from avakas.flavors.chef import AvakasChefProject
from avakas.flavors.erlang import AvakasErlangProject
from avakas.flavors.git import AvakasGitNative
from avakas.flavors.node import AvakasNodeProject

__all__ = [
    'AvakasAnsibleProject',
    'AvakasChefProject',
    'AvakasErlangProject',
    'AvakasGitNative',
    'AvakasLegacy',
    'AvakasNodeProject',
]
