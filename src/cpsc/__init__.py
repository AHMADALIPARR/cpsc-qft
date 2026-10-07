"""Conservation-Preserving Scattering Compiler, research prototype."""

from cpsc.analyzer import Gate, SymmetryAnalyzer, Rejection
from cpsc.channel import evolve_in_sector, sector_basis

__all__ = [
    "Gate",
    "Rejection",
    "SymmetryAnalyzer",
    "evolve_in_sector",
    "sector_basis",
]
__version__ = "0.1.0"
