![Logo](CSCLogo.png)

---

A supply chain modeling framework based on `JuMP` implementing the coordination model described described by [Tominac and Zavala](https://doi.org/10.1016/j.compchemeng.2020.107157). CoordinatedSuppylChains automates this implementation; users can point it at a set of data files, and the package will build the model, solve it, save solution variables to .csv files, and create basic network plots of the system. For more control, users can call functions one-by-one, giving access to all intermediate data structures, or simply point a single convenient function at a directory with the required data files, and CoordinatedSupplyChains will do the rest. The present release supports steady state coordination, with dynamic coordination based on [Tominac, Zhang, and Zavala](https://arxiv.org/abs/2106.13836) planned for a future release.

| **Documentation**                                                               | **Build Status**                                                                                | **Citation** |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|:--------------------------------------:|
||[![Build Status](https://github.com/Tominapa/CoordinatedSupplyChains.jl/workflows/CI/badge.svg)](https://github.com/Tominapa/CoordinatedSupplyChains.jl/actions)[![Coverage](https://codecov.io/gh/Tominapa/CoordinatedSupplyChains.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Tominapa/CoordinatedSupplyChains.jl)|![DOI(https://img.shields.io/badge/DOI-Elsevier-orange)](https://doi.org/10.1016/j.compchemeng.2020.107157)|


