"""
Avakas Built-In Project Flavors
"""

from avakas.flavors.base import AvakasLegacy
from avakas.flavors.ansible import AvakasAnsibleProject
from avakas.flavors.git import AvakasGitNative
from avakas.flavors.node import AvakasNodeProject
from avakas.flavors.pep621 import AvakasP621Project

__all__ = [
    'AvakasAnsibleProject',
    'AvakasGitNative',
    'AvakasLegacy',
    'AvakasNodeProject',
    'AvakasP621Project',
]
