![Logo](..CSCLogo.png)

---

## What is CoordinatedSupplyChains.jl?

`CoordinatedSupplyChains.jl` encodes a complex abstraction for large-scale supply chains into a simple, user-friendly interface that removes almost all the coding burden separating the user from the results. `CoordinatedSupplyChains.jl` is intended for users who want to solve supply chain problems under a coordination objective (i.e., supply chains as coordinated markets). It is intended to function equally well for users in practical settings (industrial practitioners) and for educators looking to teach complex operations research concepts. `CoordinatedSupplyChains.jl` is built around a coordination model abstraction; users only need to supply properly formatted data files to the package, `CoordinatedSupplyChains.jl` parses these into the model, solves the user-defined supply chain problem, and returns all the output variables to the user, along with model statistics, and a standardized network plot.

## Citing
[![DOI](https://img.shields.io/badge/DOI-Elsevier-orange)](https://doi.org/10.1016/j.compchemeng.2020.107157)

If `CoordinatedSupplyChains.jl` is useful in your research, we appreciate your citation to our work. This helps us promote new work and development on our code releases. We hope you find our code helpful, and thank you for any feedback you might have for us.

```latex
@article{TominacZavala2020,
	title = {Economic properties of multi-product supply chains},
	journal ={Comput Chem Eng},
	pages = {107157},
	year = {2020},
	issn = {0098-1354},
	doi ={https://doi.org/10.1016/j.compchemeng.2020.10715},
	url = {http://www.sciencedirect.com/science/article/pii/S0098135420305810},
	author = {Philip A. Tominac and Victor M. Zavala}
}
```