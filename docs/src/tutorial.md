## Overview

`CoordinatedSupplyChains.jl` is a user-friendly tool designed to give you access to a powerful supply chain coordination model. `CoordinatedSupplyChains.jl` handles the data processing and model building so that you can quickly solve problems and generate results.

Putting together a supply chain problem is a matter of populating comma-separated-values files with the necessary definitions of the supply chain structure and the stakeholders participating in it. Once this is complete, you can point `CoordinatedSupplyChains.jl` to your data and run the code to generate results.

## Coordination Abstraction

`CoordinatedSupplyChains.jl` is based on the coordination model by [Tominac & Zavala](https://doi.org/10.1016/j.compchemeng.2020.107157) and its more recent iteration described by [Tominac, Zhang, & Zavala](https://www.sciencedirect.com/science/article/pii/S0098135422000114).

The `CoordinatedSupplyChains.jl` abstraction conceptualizes a supply chain as a market operating under a coordination system, like an auction where each stakeholder is bidding its preferred buying rate, its selling rate, or its service rate. This coordination system is managed by a coordinator, an independent operator who does not have a stake in the market, but whose goal is to maximize the total profit of the market. The stakeholders pass their bidding information to the coordinator, who resolves the market by setting product and service prices. As a result, transactions of products and services are allocated to stakeholders. The coordination system has a number of useful theoretical guarantees related to the coordinator's price setting practices and the implications for supply chain stakeholders.
1. No stakeholder loses money as a result of participation in the coordination system. A stakeholder either participates in the market with a positive allocation and nonnegative profit, or it does not participate in the market at all. Market participation is never coerced.
2. The coordinator's prices respect participating stakeholder bids. This is the mechanism by which nonnegative profits are guaranteed.
3. Coordination is efficient; there is no money lost to the coordinator or from the supply chain as a result of operating under the coordination system. In other words, money balances within a coordinated supply chain.

For a complete review of the auction system, please refer to the associated references.


## Supply Chain Representation

`CoordinatedSupplyChains.jl` uses a compact graph representation to describe a supply chain. The graph is defined by:
- A set of geographical (location) nodes
- A set of time points
- A set of spatiotemporal arcs that move products through space and time

Of interest within a coordinated supply chain are
- A set of products to be transacted
- A set of environmental impacts associated with the economic activities in the supply chain

Transacting products and providing services are the supply chain stakeholders. These are divided into five distinct categories, namely
- suppliers, who sell products
- consumers, who purchase products
- transportation providers, who move products between spatiotemporal nodes in the supply chain graph
- technology providers, who transform products from one form to another
- environmental impact consumers, who absorb the environmental impacts emitted by other stakeholders

With this graph abstraction and the five stakeholder categories, it is possible to build representations of complex supply chain systems including product processing and sustainability metrics. 


## Data Format

Any coordinated supply chain problem is defined by data detailing the sets of nodes, time points, arcs, products, impacts, and stakeholders. This data is divided into ten specially named .csv files. These are comma-separated by default, so any convenient .csv editor (text editor or spreadsheet software) will work. The file name rconventions are as follows:
- csvdata_node.csv
- csvdata_time.csv (optional)
- csvdata_arcs.csv (optional)
- csvdata_product.csv
- csvdata_impact.csv (optional)
- csvdata_demand.csv
- csvdata_supply.csv
- csvdata_env.csv (optional)
- csvdata_tech.csv. (optional)
- csvdata_techmap.csv (optional)

Note: not every supply chain problem requires every feature built into `CoordinatedSupplyChains.jl` and as such, certain files are optional. For example, if solving a steady-state supply chain problem, the csvdata_time.csv file may be excluded, and the package will simply assign variables a time index `T0`. Similarly, you may wish to build supply chain problems with no arcs; the package will accommodate this as well. For models with no sustainability focus, the impact and environmental stakeholder data folders may be excluded. Similarly, if there are no technologies, then the technology and mapping files may be excluded. No keywords or arguments are required; the package is programmed to check for the requisite files and proceed accordingly. The minimal `CoordinatedSupplyChains.jl` model must include one or more nodes, products, suppliers, and consumers. These four files are thus non-optional inputs.

A working example will be used to illustrate how these files are structured. You can copy each of the ten files to replicate the example on your own.


### csvdata_node.csv

Node data are structured as follows
1. Node ID: a unique string ID for the node, preferably of the form N01, N02, ...; no spaces allowed!
2. Node Name: a string with detailed information about the node; spaces allowed
3. Node longitude: A number representing the longitude of the node; e.g. Madison is -89.4012
4. Node latitude: A number representing the latitude of the node; e.g. Madison is 43.0731

Our example uses the following node data
```
# 1. Node ID, 2. Node Name, 3. Node longitude, 4. Node latitude
N1,Madison-WI,-89.4,43.1
N2,Austin-TX,-97.7,30.3
N3,Los Angeles-CA,-118.2,34.0
```

You may need to be careful when looking for longitude/latitude data; conventions can differ. However, `CoordinatedSupplyChains.jl` uses the same convention as Google maps, with negative longitude.


### csvdata_time.csv

Time data are structure as follows
1. Time point ID: a unique string ID for the time point; no spaces allowed
2. Time point duration: A number representing the duration of the time point; used for calculating temporal transportation costs

```
# 1. Time point ID,2. Duration
T1,1.0
T2,1.0
T3,1.0
T4,1.0
T5,1.0
```

In this example, we use five time points of equal duration; this is not a requirement. Duration can vary,  and any time-dependent parameters will reflect the duration.


### csvdata_product.csv

Data defining products is arranged with columns numbered as follows
1. Product ID: a unique string ID for the product; no spaces allowed!
2. Product name: a string with detailed information about the product; spaces allowed
3. Transportation cost (distance): the transport cost to move the product over distance; needs to be positive to prevent transportation cycles
4. Transportation cost (time): the cost to store, or move the product through time

The demo product file is
```
# 1. Product no.,2. Product name,3. Transportation cost (distance) (USD.tonne^-1.km^-1),4. Transportation cost (time) (USD.tonne^-1.h^-1)
Milk,Milk,0.30,0.20
IceCream,Ice cream - tonne,0.30,0.20
Beef,Beef - boneless sirloin steak - USDA choice - tonne,0.25,0.05
Almonds,Almonds - shelled unseasoned - tonne,0.20,0.15
```

Product names have been used as IDs, with a more detailed description provided in column 2. Transportation costs in columns 3 and 4 are included with units provided in the column headers, as good record keeping practice. It is on the user to keep track of units and ensure they are. consistent.

### csvdata_impact.csv

Data for environmental impact types are formatted as follows
1. Impact ID: a unique string ID for the impact; no spaces allowed!
2. Impact alias: a string with detailed information about the impact measure
3. Transportation coefficient (distance): Some environmental impacts are associated with transportation; the emission coefficient per unit distance is recorded here
4. Storage coefficient (time): Some environmental impacts are associated with storage; the emission coefficient per unit time is recorded here

For our demo, we will use the following
```
# 1. Impact ID, 2. Impact alias, 3. Transportation coefficient (impact unit per tonne.km), 4. Storage coefficient (impact unit per tonne.h)
Phosphorus,phosphorus equivalent eutrophication potential - tonne P-eq,0.0,0.0
CO2,Carbon dioxide emissions - tonne CO2-eq,0.01,0.001
WaterUse,Water use - tonne,0.0,0.0
```


### csvdata_arcs.csv

Arc data are structured as follows
1. Arc ID: a unique string ID for the arc, prefereably of the form A01, A02, ...; no spaces allowed!
2. Arc first node: a Node ID included in node_data.csv
3. Arc second node: a Node ID included in node_data.csv
4. Arc capacity: a vector of numbers representing the product capacity of the arc; units (tonne)
5. Custom length (optional): A number representing the length of the arc; units: (km); used only if the CustomLengths parameter is set true; >=0

Our example has the following arcs
```
# 1. Arc ID, 2. Arc first node, 3. Arc second node, 4. Arc capacity, 5. Arc Length
A1,N1,N2,1E6|1E6|1E6|1E6,
A2,N2,N3,1E6|1E6|1E6|1E6,
A3,N3,N1,1E6|1E6|1E6|1E6,
```

This is the first data file that depends on others; csvdata_arcs.csv is built based on data in csvdata_node.csv and csvdata_product.csv. The CustomLengths field is unpopulated in this example because it will not be used. We could populate ourselves, if we knew specific route distances. Custom arcs lengths are useful if you already have access to distance data. In this example, we will let the software calculate great circle distances between nodes connected by arcs. The built-in great-circle distance function returns arc lengths in kilometers.

Note that arcs only need to be defined in one direction; e.g., from node N1 to N2 will allow products to flow from N1 to N2, and from N2 to N1.

Arc product capacities are provided as a vector, but note that product order will follow the order of products in csvdata_product.csv file.


### csvdata_supply.csv

Supplier data are structured as follows
1. Supply ID: a unique string ID for the supplier; no spaces allowed!
2. Node: a Node ID included in csvdata_node.csv, where the supplier is located
3. Time: a Time point ID included in csvdata_time.csv, when the supply is available
4. Product: a Product ID included in csvdata_product.csv that the supplier will offer for sale
5. Bid: a number representing the supplier bid for a product; a real number
6. Capacity: a number representing the maximum amount supplied;  a positive number
7. Emissions: a vector of impact IDs from csvdata_impact representing the impacts associated with supplying the product
8. Emissions coefficients: a vector of real numbers representing the per unit emissions associated with supplying the product

The demo supply file
```
# 1.Supply reference no., 2.Node, 3.Time, 4.Product, 5.Bid, 6.Capacity, 7. Emissions, 8. Emissions coefficients unit per tonne product consumed
G01,N1,T1,Milk,1150.0,1.12,Phosphorus|CO2|WaterUse,0.0024|0.100|1020.0
G02,N1,T2,Milk,1150.0,1.12,Phosphorus|CO2|WaterUse,0.0024|0.100|1020.0
G03,N1,T3,Milk,1150.0,1.12,Phosphorus|CO2|WaterUse,0.0024|0.100|1020.0
G04,N3,T4,Milk,1150.0,1.12,Phosphorus|CO2|WaterUse,0.0024|0.100|1020.0
G05,N3,T5,Milk,1150.0,1.12,Phosphorus|CO2|WaterUse,0.0024|0.100|1020.0
G06,N2,T3,Beef,23479.23,1.0,Phosphorus|CO2|WaterUse,0.0108|33.1|15415.0
G07,N2,T4,Beef,23479.23,1.0,Phosphorus|CO2|WaterUse,0.0108|33.1|15415.0
G08,N2,T5,Beef,23479.23,1.0,Phosphorus|CO2|WaterUse,0.0108|33.1|15415.0
G09,N3,T1,Almonds,6018.01,1.0,Phosphorus|CO2|WaterUse,0.144|2.009|12984.0
G10,N3,T2,Almonds,6018.01,1.0,Phosphorus|CO2|WaterUse,0.144|2.009|12984.0
```


### demand_data.csv

Consumer data are structured as follows
1. Demand ID: a unique string ID for the consumer; no spaces allowed!
2. Node: a Node ID included in csvdata_node.csv, where the consumer is located
3. Time: a Time point ID included in csvdata_time.csv, when the consumer is available
4. Product: a Product ID included in csvdata_product.csv that the consumer will offer to buy
5. Bid: a number representing the consumer bid for a product; a real number
6. Capacity: a number representing the maximum amount consumed; a positive number
7. Emissions: a vector of impact IDs from csvdata_impact representing the impacts associated with consuming the product
8. Emissions coefficients: a vector of real numbers representing the per unit emissions associated with consuming the product

Our example has five consumers
```
# 1.Demand reference no., 2.Node, 3.Time, 4.Product, 5.Bid, 6.Capacity, 7. Emissions, 8. Emissions coefficients unit per tonne product consumed
D01,N1,T1,IceCream,30000.00,0.3,,
D02,N1,T2,IceCream,30000.00,0.3,,
D03,N1,T3,IceCream,30000.00,0.3,,
D04,N1,T4,IceCream,30000.00,0.3,,
D05,N1,T5,IceCream,30000.00,0.3,,
D06,N2,T1,IceCream,30000.00,0.3,,
D07,N2,T2,IceCream,30000.00,0.3,,
D08,N2,T3,IceCream,30000.00,0.3,,
D09,N2,T4,IceCream,30000.00,0.3,,
D10,N2,T5,IceCream,30000.00,0.3,,
D11,N3,T1,IceCream,35000.00,0.4,,
D12,N3,T2,IceCream,35000.00,0.4,,
D13,N3,T3,IceCream,35000.00,0.4,,
D14,N3,T4,IceCream,35000.00,0.4,,
D15,N3,T5,IceCream,35000.00,0.4,,
D16,N1,T1,Almonds,6800,0.2,,
D17,N1,T2,Almonds,6800,0.2,,
D18,N2,T1,Almonds,6020,0.6,,
D19,N2,T2,Almonds,6020,0.6,,
D20,N3,T1,Almonds,6800,0.2,,
D21,N3,T2,Almonds,6800,0.2,,
D22,N1,T3,Beef,25000,0.2,,
D23,N1,T4,Beef,25000,0.2,,
D24,N1,T5,Beef,25000,0.2,,
D25,N2,T3,Beef,24000,0.4,,
D26,N2,T4,Beef,24000,0.4,,
D27,N2,T5,Beef,24000,0.4,,
D28,N3,T3,Beef,25000,0.4,,
D29,N3,T4,Beef,25000,0.4,,
D30,N3,T5,Beef,25000,0.4,,
```


###csvdata_env.csv

This data file defines environmental impact consumption and policy, and consists of
1. Environmental. stakeholder ID: a unique ID for the environmental stakeholder
2. Node: a Node ID included in csvdata_node.csv, where the environmental stakeholder is located
3. Time: a Time point ID included in csvdata_time.csv, when the environmental stakeholder is available
4. Impact: an Impact ID included in csvdata_impact.csv that the environmental stakeholder will coonsumer
5. Bid: a number representing the environmental stakeholder bid for a product; a real number
6. Capacity: a number representing the maximum amount consumed; a positive number

Environmental stakeholder data for the demo
```
# 1. Env. stakeholder reference, 2. Node, 3. Time, 4. Impact, 5. Bid (USD/impact unit), 6. Capacity
V01,N1,T1,Phosphorus,0,Inf
V02,N1,T2,Phosphorus,0,Inf
V03,N1,T3,Phosphorus,0,Inf
V04,N1,T4,Phosphorus,0,Inf
V05,N1,T5,Phosphorus,0,Inf
V06,N2,T1,Phosphorus,0,Inf
V07,N2,T2,Phosphorus,0,Inf
V08,N2,T3,Phosphorus,0,Inf
V09,N2,T4,Phosphorus,0,Inf
V10,N2,T5,Phosphorus,0,Inf
V11,N3,T1,Phosphorus,0,Inf
V12,N3,T2,Phosphorus,0,Inf
V13,N3,T3,Phosphorus,0,Inf
V14,N3,T4,Phosphorus,0,Inf
V15,N3,T5,Phosphorus,0,Inf
V16,N1,T1,CO2,0,Inf
V17,N1,T2,CO2,0,Inf
V18,N1,T3,CO2,0,Inf
V19,N1,T4,CO2,0,Inf
V20,N1,T5,CO2,0,Inf
V21,N2,T1,CO2,0,Inf
V22,N2,T2,CO2,0,Inf
V23,N2,T3,CO2,0,Inf
V24,N2,T4,CO2,0,Inf
V25,N2,T5,CO2,0,Inf
V26,N3,T1,CO2,0,Inf
V27,N3,T2,CO2,0,Inf
V28,N3,T3,CO2,0,Inf
V29,N3,T4,CO2,0,Inf
V30,N3,T5,CO2,0,Inf
V31,N1,T1,WaterUse,0,Inf
V32,N1,T2,WaterUse,0,Inf
V33,N1,T3,WaterUse,0,Inf
V34,N1,T4,WaterUse,0,Inf
V35,N1,T5,WaterUse,0,Inf
V36,N2,T1,WaterUse,0,Inf
V37,N2,T2,WaterUse,0,Inf
V38,N2,T3,WaterUse,0,Inf
V39,N2,T4,WaterUse,0,Inf
V40,N2,T5,WaterUse,0,Inf
V41,N3,T1,WaterUse,0,Inf
V42,N3,T2,WaterUse,0,Inf
V43,N3,T3,WaterUse,0,Inf
V44,N3,T4,WaterUse,0,Inf
V45,N3,T5,WaterUse,0,Inf
```


### technology_data.csv

Technology data are structures as follows. Pay attention to these definitions; technology data are the most complex to set up.
1. Tech ID: a unique string ID for the technology, no spaces allowed!
2. Tech Outputs: a vertical bar-delimited list of Product IDs included in csvdata_product.csv; e.g., ",P05|P06,"
3. Tech Inputs: a vertical bar-delimited list of Product IDs included in csvdata_product.csv; e.g., ",P01|P02|P04,"
4. Tech Impacts: a vertical bar-delimited list of Impact IDs included in csvdata_impact.csv; e.g., ",GWP|NH3,"
5. Output Yield: a vertical bar-delimited list of yield parameters (positive) the same length as "Tech Outputs"; e.g., "|0.4|0.3|0.6|"
6. Input Yield: a vertical bar-delimited list of yield parameters (positive) the same length as "Tech Inputs"; e.g., ",1.0|0.7|0.6,"- one of these MUST be 1.0! see 6. Reference Product
7. Impact Yield: a vertical bar-delimited list of impact parameters (positive) the same length as "Tech Impacts"; e.g., ",0.045|0.0033|0.01,"
8. Reference product: a Product ID included in csvdata_product.csv; this is used as the basis for the technology, and its yield coefficient in 5. Input Yield MUST be 1.0.
9. Bid: a number representing the technology bid for a product; positive
10. Capacity: a number representing the maximum amount of reference product processed; positive
11. Name: a string with detailed information about the technology; spaces allowed

The technology data in our example are as follows
```
# 1. Tech ID,2. Tech Outputs,3. Tech Inputs,4. Tech Impacts,5. Output stoich,6. Input stoich,7. Impact stoich,8. Reference product,9. Operating bid (USD/tonne),10. Capacity,11. alias
M1,IceCream,Milk,Phosphorus|CO2|WaterUse,0.178,1.0,0.00065|3.94|2050.0,Milk,3861.11,Inf,IceCream production (extant)
M2,IceCream,Milk,Phosphorus|CO2|WaterUse,0.178,1.0,0.00065|2.94|2050.0,Milk,3999.99,Inf,IceCream production (CO2 emissions reduced 1 tonne)
```

Note that technology_data.csv embeds vertical bar-delimited lists inside a comma-delimited data file. This condenses our representation.


### csvdata_techmap.csv

The final data file, called "techmap" (because it maps instances of technologies onto the supply chain) is structured as follows
1. Tech location ID: a unique string ID for the technology mapping; no spaces allowed!
2. Tech ID: a Technology ID included in csvdata_technology.csv
3. Node ID: a Node ID included in csvdata_node.csv
4. Time ID: a Time ID included in csvdata_time.csv

Our example uses the following techmap entries
```
# 1. Tech location reference ID,2. Node ID,3. Time ID,4. Tech ID
L01,N1,T1,M1
L02,N1,T2,M1
L03,N1,T3,M1
L04,N1,T4,M1
L05,N1,T5,M1
```

Technologies are defined in csvdata_technology.csv in a general form, and are not mapped onto the supply chain. The technology-node pairs in csvdata_techmap.csv serve this function, allowing multiple copies of a technology to be placed at supply chain nodes; i.e., L1,M1,N1,T1 and L2,M1,N2,T1 creates two "copies" of technology M1 at nodes N1 and N2, treated as separate entities in the model. This can reduce the size and complexity of managing large numbers of technologies.


## Basic Usage

`CoordinatedSupplyChains.jl` is built to streamline your workflow with supply chain problems. It handles all the data input and output, as well as model building and solution. The user's responsibility is to set up the input data files defining their supply chain problem correctly. Consequently, the simplest usage of the package requires no more than pointing to the source data files.

```
RunCSC()
```

In this example, it is assumed that Julia is currently running in the same directory as the data files, and defaults to the current directory. This way `RunCSC()` can be used without an argument. The function has three keyword arguments as well, allowing you to tune your experience.

1. optimizer; default: Clp.Optimizer
2. UseArcLengths; default: true
3. Output: default: false

The first optional keyword argument is `optimizer` allowing the user to provide a different optimizer to solve their supply chain problem. By default, the open-source Clp optimizer is used. The user may want to use a licensed optimizer instead. This can be achieved by passing the optimizer argument:

```
RunCSC(optimizer=Gurobi.Optimizer)
```

The next keyword argument is `UseArcLengths` defaulting to a value of `true`. This keyword allows the user to change the behavior of `CoordinatedSupplyChains.jl` with respect to arcs. By. default, the package will use the arc lengths provided by the user in csvdata_arcs.csv. However, these may be difficult or tedious to calculate by hand, especially if the user's supply chain has many connecting arcs. By passing

```
RunCSC(UseArcLengths=false)
```

the package will instead calculate great circle lengths for the arcs according to the node latitude and longitude data provided. This keyword provides a convenient means of estimating distances between locations.

The final keyword `Output` (defaulting to `false`)  allows the user to specify that all model data should be returned once the code has run. This allows that user to inspect data structures manually. This keyword requires that the user indicate output names with the call to `RunCSC()`. The suggested naming convention is optional, but the number of outputs is required

```
T, N, P, Q, A, D, G, V, M, L, Subsets, Pars, MOD, ModelStats, SOL, POST = RunCSC(Output=true)
```

In order, the outputs are:
- `T`: time data structure
- `N`: node data structure
- `P`: product data structure
- `Q`: impact data structure
- `A`: arc data structure
- `D`: demand data structure
- `G`: supply data structure
- `V`: environmental stakeholder data structure
- `M`: technology data structure
- `L`: technology mapping data structure
- `Subsets`: Subsets used in the model
- `Pars`: parameters used in the model
- `MOD`: JuMP model
- `ModelStats`: structure containing model statistics
- `SOL`: structure containing the model solution data
- `POST`: structure containing post-solution values calculated following the model solve

Note that most of this data is made available to the user in the solution output, all of which is stored in a folder called "_SolutionData" in the directory with the model data. If the user wants to access, for example, the JuMP model following the solve, this keyword makes this possible. With the exception of `MOD` which is a JuMP model structure (see the JuMP documentation on [Models](https://jump.dev/JuMP.jl/stable/manual/models/)) these outputs are all custom Julia data structures. They are primarily defined for convenient model representation within `CoordinatedSupplyChains.jl` but you may want to have access to them for use in data manipulations or plotting solutions. Each structure has a number of fields containing data, which are accessed with a syntax `[sstructure_name].[field_name][index]`. The fields are as follows.

Time structure
```
T
	ID::Array - time point IDs
   	dt::Dict - time point durations
```

Node structure
```
N
	ID::Array - node IDs
    	alias::Dict - node names
    	lon::Dict - node longitudes
    	lat::Dict - node latitudes
```

Product structure
```
P
	ID::Array - product IDs
    	alias::Dict - product names
    	transport_cost::Dict - product transportation costs
    	storage_cost::Dict - product storage costs
```

Impact structure
```
Q
	ID::Array - impact IDs
    	alias::Dict - impact names
    	transport_coeff::Dict - impact transportation emission coefficients
    	storage_coeff::Dict - impact storage emission coefficients
```

Arc structure
```
A
	ID::Array - arc IDs
    	n_send::Dict - arc sending node
    	n_recv::Dict. - arc receiving node
    	t_send::Dict - arc sending time point
    	t_recv::Dict - arc receiving time point
    	bid::Dict - arc bid
    	cap::Dict - arc capacities
    	len::Dict - arc length
    	dur::Dict - arc duration
   	ID_S::Array - array of arc IDs that are purely spatial
    	ID_T::Array - array of arc IDs that are purely temporal
    	ID_ST::Array - array of arc IDs that are spatiotemporal
```

Demand structure
```
D
	ID::Array - demand IDs
    	node::Dict - consumer node
    	time::Dict - demand time point
    	prod::Dict - demand product
    	bid::Dict - demand bid
    	cap::Dict - demand capacity
    	Impacts::Dict - impacts associated with demand
    	ImpactYields::Dict - impact coefficients
```

Supply structure
```
G
	ID::Array - supply IDs
    	node::Dict - supplier node
    	time::Dict - supply time point
    	prod::Dict - supply product
    	bid::Dict - supply bid
    	cap::Dict - supply capacity
    	Impacts::Dict - impacts associated with supply
    	ImpactYields::Dict - impact coefficients
```

Environmental stakeholder structure
```
V
	ID::Array - e.s. IDs
    	node::Dict - e.s. node
    	time::Dict - e.s. time point
    	impact::Dict - .e.s. impact
    	bid::Dict - e.s. bid
    	cap::Dict - e.s. capacity
```

Technology structure
```
M
	ID::Array - technology ID
    	Outputs::Dict - technology output products
    	Inputs::Dict - technology input products
    	Impacts::Dict - technology impacts
    	OutputYields::Dict - technology output product yield coefficients
    	InputYields::Dict - technology input product yield coefficients
    	ImpactYields::Dict - technology impact yield coefficients
    	InputRef::Dict - technology reference product
    	bid::Dict - technology bid
    	cap::Dict - technology capacity
    	alias::Dict - technology name
```

Technology mapping structure
```
L
	ID::Array - technology mapping ID
    	node::Dict - technology instance node
    	time::Dict - technology instance time
    	tech::Dict - technology instance type
```

Subset structure
```
Subsets
	T1::Array - set containing the first time point
    	Tt::Array - set containing all time points except the last
    	TT::Array - set containing all time points except the first
    	Tprior::Dict - maps the prior time point to the current one
    	Tpost::Dict - maps the subsequent time point to the current one
   	Ain::Union{Dict, Nothing} - all arcs inbound upon a node
    	Aout::Union{Dict, Nothing} - all arcs outbound from a node
    	Dntp::Dict - returns consumers by node, time point, and product indices
    	Gntp::Dict - returns suppliers by node, time point, and product indices
    	Dntq::Union{Dict, Nothing} - returns consumers by node, time point, and impact indices
    	Gntq::Union{Dict, Nothing} - returns suppliers by node, time point, and impact indices
    	Vntq::Union{Dict, Nothing} - returns environmental stakeholders by node, time point, and impact indices
    	DQ::Union{Array, Nothing} - returns all consumers with some environmental impact
    	GQ::Union{Array, Nothing} - returns all suppliers with some environmental impact
    	NTPgenl::Union{Dict, Nothing} - returns technology instances at a node and time point generating product p
    	NTPconl::Union{Dict, Nothing} - returns technology instances at a node and time point consuming product p
    	NTQgenl::Union{Dict, Nothing} - returns technology instances at a node and time point with impact q
```

Parameter structure
```
Pars
	gMAX::Dict - supply allocation maxima
    	dMAX::Dict - demand allocation maxima
    	eMAX::Union{Dict, Nothing} - environmental stakeholder consumption maxima
    	γiq::Union{Dict, Nothing} - environmental impact yield coefficient for suppliers
    	γjq::Union{Dict, Nothing} - environmental impact yield coefficient for consumers
    	γaq::Union{Dict, Nothing} - environmental impact yield coefficient for transportation
    	γmp::Union{Dict, Nothing} - technology product yield coefficients
    	γmq::Union{Dict, Nothing} - environmental impact yield coefficient for technologies
    	ξgenMAX::Union{Dict, Nothing} - technology generation maxima
    	ξconMAX::Union{Dict, Nothing} - technology consumption maxima
    	ξenvMAX::Union{Dict, Nothing} - technology impact maxima
```

Model statistics structure
```
ModelStats
	Variables::Int - number of model variables
    	TotalInequalityConstraints::Int - total number of inequality constraints
    	TotalEqualityConstraints::Int - total number of equality constraints
    	VariableBounds::Int - number of model variable bounds
    	ModelInequalityConstrtaints::Int - number of model inequality constraints
    	ModelEqualityConstraints::Int - number of model equality constraints
```

Model solution data
```
SOL
	TermStat::String - termination status
    	PrimalStat::String - primal solution status
    	DualStat::String - dual solution status
    	z::Float64 - objective values
    	g::JuMP.Containers.DenseAxisArray - supply allocations
    	d::JuMP.Containers.DenseAxisArray - demand allocations
    	e::Union{JuMP.Containers.DenseAxisArray,Nothing} - environmental stakeholder allocations
    	f::Union{JuMP.Containers.DenseAxisArray,Nothing} - transportation allocations
    	ξ::Union{JuMP.Containers.DenseAxisArray,Nothing} - technology allocations
    	πp::JuMP.Containers.DenseAxisArray - product nodal prices
    	πq::Union{JuMP.Containers.DenseAxisArray,Nothing} - impact nodal prices
```

Derived solution values
```
POST
	gNTP::Dict - nodal supply allocations
    	dNTP::Dict - nodal demand allocations
    	eNTQ::Union{Dict,Nothing} - nodal environmental stakeholder allocations
    	ξgen::Union{Dict,Nothing} - technology allocations, generation
    	ξcon::Union{Dict,Nothing} - technology allocations, consumption
    	ξenv::Union{Dict,Nothing} - technology allocations, impact
    	π_iq::Union{Dict,Nothing} - supplier impact prices
    	π_jq::Union{Dict,Nothing} - consumer impact prices
    	π_a::Union{Dict,Nothing} - transportation prices
    	π_aq::Union{Dict,Nothing} - transportation impact prices
    	π_m::Union{Dict,Nothing} - technology prices
    	π_mq::Union{Dict,Nothing} - technology impact prices
    	ϕi::Dict - supplier profits
    	ϕj::Dict - consumer profits
    	ϕv::Union{Dict,Nothing} -  environmental stakeholder profits
    	ϕl::Union{Dict,Nothing} - technology profits
    	ϕa::Union{Dict,Nothing} - transportation profits
```