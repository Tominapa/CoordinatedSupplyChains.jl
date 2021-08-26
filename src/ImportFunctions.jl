################################################################################
### FUNCTIONS FOR IMPORTING STANDARDIZED MODEL DATA
"""
    A,N,P,D,S,T,L,Sets,Pars = LoadSSCaseData(CaseDataDirectory=pwd())

# Arguments

CaseDataDirectory: file directory for supply chain case study data; defaults to current Julia directory if not specified
CustomLengths=false: (optional keyword arg) set true to use custom arc lengths from file; default, calculate arc lengths from node lon/lat
PrintSpacer="*"^50: (optional keyword arg) some text to be printed to the REPL as a spacer for outputs

# Returns

Data strucutures with inputs prepared for JuMP model
A - arc structure
N - node structure
P - product structure
D - demand data structure
S - supply data structure
T - technology data structure
L - technology site data structure
Sets - additional sets required for JuMP model
Pars - additional parameters required for JuMP model
```
Loads standardized data files for steady-state supply chains

Data files required are:
    arc_data.csv
    node_data.csv
    product_data.csv
    demand_data.csv
    supply_data.csv
    technology_data.csv
    techsite_data.csv

Files must be formatted as .csv (Comma Separated Values) delimited with the VeticalBar character (|). Formatting for each file is as follows, with columns ordered as indicated, containing:
    arc_data.csv:
        1. Arc ID: a unique string ID for the arc, prefereably of the form A01, A02, ...; no spaces allowed!
        2. Arc first node: a Node ID included in node_data.csv
        3. Arc second node: a Node ID included in node_data.csv
        4. Arc capacity: a number representing the capacity of the arc; units (tonne)
        5. Custom length (optional): A number representing the length of the arc; units: (km); used only if the CustomLengths paramter is set true; >=0
    node_data.csv:
        1. Node ID: a unique string ID for the node, prefereably of the form N01, N02, ...; no spaces allowed!
        2. Node Name: a string with detailed information about the node; spaces allowed
        3. Node longitude: A number representing the longitude of the node; e.g. Madison is -89.4012
        4. Node latitude: A number representing the latitude of the node; e.g. Madison is 43.0731
    product_data.csv:
        1. Product ID: a unique string ID for the product, prefereably of the form P01, P02, ...; no spaces allowed!
        2. Product name: a string with detailed information about the product; spaces allowed
        3. Transportation cost: the transport cost for the product; units: (USD.tonne^-1.km^-1); >0
    demand_data.csv:
        1. Demand ID: a unique string ID for the demand, prefereably of the form D01, D02, ...; no spaces allowed!
        2. Node: a Node ID included in node_data.csv
        3. Product: a Product ID included in product_data.csv
        4. Bid: a number representing the consumer bid for a product; units: (USD.tonne^-1); any real number
        5. Capacity: a number representing the maximum amount demanded; units (tonne); >0
        6. Notes: any notes about this demand instance; spaces allowed
    supply_data.csv:
        1. Supply ID: a unique string ID for the supply, prefereably of the form S01, S02, ...; no spaces allowed!
        2. Node: a Node ID included in node_data.csv
        3. Product: a Product ID included in product_data.csv
        4. Bid: a number representing the supplier bid for a product; units: (USD.tonne^-1); any real number
        5. Capacity: a number representing the maximum amount supplied; units (tonne); >0
        6. Notes: any notes about this supply instance; spaces allowed
    technology_data.csv:
        1. Tech ID: a unique string ID for the technology, prefereably of the form M01, M02, ...; no spaces allowed!
        2. Tech Outputs: a comma-delimited list of Product IDs included in product_data.csv; e.g., |P05,P06| (if single product no commas required)
        3. Tech Inputs: a comma-delimited list of Product IDs included in product_data.csv; e.g., |P01,P02,P04| (if single product no commas required)
        4. Output Yield: a comma-delimited list of yield parameters (>0) the same length as "Tech Outputs"; e.g., |0.4,0.3,0.6|
        5. Input Yield: a comma-delimited list of yield parameters (>0) the same length as "Tech Inputs"; e.g., |1.0,0.7,0.6| - one of these MUST be 1.0! see: 6. Reference Product
        6. Reference product: a Product ID included in product_data.csv; this is used as the basis for the technology, and it's yield coefficient in 5. Input Yield MUST be 1.0.
        7. Bid: a number representing the technology bid for a product; units: (USD.tonne^-1 of reference product); >0
        8. Capacity: a number representing the maximum amount of reference product processed; units (tonne); >0
        9. Name: a string with detailed information about the technology; spaces allowed
    techsite_data.csv:
        1. Tech location ID: a unique string ID for the technology, prefereably of the form L01, L02, ...; no spaces allowed!
        2. Tech ID: a Technology ID included in technology_data.csv
        3. Node ID: a Node ID included in node_data.csv

Note on Technologies and TechSites:
    Technologies are defined in technology_data.csv in a general form, and are not mapped onto the supply chain. The technology-node pairs in techsite_data.csv serve this function, allowing multiple copies of a technology to be placed at different nodes without defining them in technology_data.csv; i.e., L01|T01|N01 and L02|T01|N02 creates two "copies" of T01 at nodes N01 and N02, treated as separate entities in the model.
```
"""
function LoadSSCaseData(CaseDataDirectory=pwd(); CustomLengths=false, PrintSpacer="*"^50)
    ################################################################################
    ### DATA IMPORT
    node_data = readdlm(CaseDataDirectory*"/node_data.csv",'|',Any,comments=true)
    arc_data = readdlm(CaseDataDirectory*"/arc_data.csv",'|',Any,comments=true)
    product_data = readdlm(CaseDataDirectory*"/product_data.csv",'|',Any,comments=true)
    demand_data = readdlm(CaseDataDirectory*"/demand_data.csv",'|',Any,comments=true)
    supply_data = readdlm(CaseDataDirectory*"/supply_data.csv",'|',Any,comments=true)
    tech_data = readdlm(CaseDataDirectory*"/technology_data.csv",'|',Any,comments=true)
    techsite_data = readdlm(CaseDataDirectory*"/techsite_data.csv",'|',Any,comments=true)

    ################################################################################
    ### DATA SETUP
    # Node data parsing
    node_id = node_data[:, 1]
    [node_id[i] = string(node_id[i]) for i = 1:length(node_id)]
    node_alias = Dict(zip(node_id, node_data[:, 2])) # node name
    node_lon = Dict(zip(node_id, node_data[:, 3])) # longitude
    node_lat  = Dict(zip(node_id, node_data[:, 4])) # latitude

    # Arc data parsing
    arc_id = arc_data[:, 1]
    [arc_id[a] = string(arc_id[a]) for a = 1:length(arc_id)] # convert to string from substring
    arc_n = Dict(zip(arc_id, arc_data[:, 2])) # first node "n"
    arc_m  = Dict(zip(arc_id, arc_data[:, 3])) # second node "m"
    arc_cap  = Dict(zip(arc_id, arc_data[:, 4])) # arc capacity
    if CustomLengths # Only need to define this data if working with customized arc lengths
        arc_len = Dict(zip(arc_id, arc_data[:, 5])) # arc length; optional for distances
    else
        arc_len = Dict()
        for a in arc_id
            arc_len[a] = GreatCircle(node_lon[arc_n[a]], node_lat[arc_n[a]], node_lon[arc_m[a]], node_lat[arc_m[a]])
        end
    end

    # Extend set of arcs to ensure that both forward and backward arcs exist
    cardA = length(arc_id)
    for a = 1:cardA
        ai = a + cardA # shift index for added arc
        push!(arc_id, "AI"*lpad(a,ndigits(cardA),"0")) # add a label; reuse numbers, use "AI" prefix
        arc_n[arc_id[ai]] = arc_m[arc_id[a]] # flip arc at new position
        arc_m[arc_id[ai]] = arc_n[arc_id[a]] # flip arc at new position
        arc_cap[arc_id[ai]] = arc_cap[arc_id[a]] # same capacity
        arc_len[arc_id[ai]] = arc_len[arc_id[a]] # same length
    end

    # Product data parsing
    product_id = product_data[:, 1]
    [product_id[i] = String(product_id[i]) for i = 1:length(product_id)]
    product_alias = Dict(zip(product_id, product_data[:, 2])) # product name
    product_trspt = Dict(zip(product_id, product_data[:, 3])) # product transport cost

    # Demand data parsing
    dem_id = demand_data[:, 1]
    [dem_id[i] = string(dem_id[i]) for i = 1:length(dem_id)]
    dem_node  = Dict(zip(dem_id, demand_data[:, 2])) # demand node
    dem_prod  = Dict(zip(dem_id, demand_data[:, 3])) # demand product
    dem_bid   = Dict(zip(dem_id, demand_data[:, 4])) # demand bid
    dem_cap   = Dict(zip(dem_id, demand_data[:, 5])) # demand capacity

    # Supply data parsing
    sup_id = supply_data[:, 1]
    [sup_id[i] = string(sup_id[i]) for i = 1:length(sup_id)]
    sup_node  = Dict(zip(sup_id, supply_data[:, 2])) # supply node
    sup_prod  = Dict(zip(sup_id, supply_data[:, 3])) # supply product
    sup_bid   = Dict(zip(sup_id, supply_data[:, 4])) # supply bid
    sup_cap   = Dict(zip(sup_id, supply_data[:, 5])) # supply capacity

    # Technology transformation parsing
    tech_id = tech_data[:, 1]
    [tech_id[i] = string(tech_id[i]) for i = 1:length(tech_id)] # de-substring-ification
    tech_output = TextListFromCSV(tech_id, tech_data[:,2]) # products made
    tech_input = TextListFromCSV(tech_id, tech_data[:, 3]) # product consumed
    tech_output_yields = NumericListFromCSV(tech_id, tech_output, tech_data[:, 4]) # product yield factor
    tech_input_yields = NumericListFromCSV(tech_id, tech_input, tech_data[:, 5]) # reference yield factor
    tech_bid_ref = Dict(zip(tech_id, tech_data[:, 6])) # reference product for bids
    [tech_bid_ref[i] = string(tech_bid_ref[i]) for i in keys(tech_bid_ref)] # de-substring-ification
    tech_bid = Dict(zip(tech_id, tech_data[:, 7])) # bid value; interpreted as operating cost
    tech_cap = Dict(zip(tech_id, tech_data[:, 8])) # capacity value
    tech_defn = Dict(zip(tech_id, tech_data[:, 9])) # technology description

    # Technology site data
    techsite_id = techsite_data[:, 1]
    [techsite_id[i] = String(techsite_id[i]) for i = 1:length(techsite_id)]
    techsite_node = Dict(zip(techsite_id, techsite_data[:, 2])) # technology node
    techsite_tech = Dict(zip(techsite_id, techsite_data[:, 3])) # technology existing at specified site

    ################################################################################
    ### PRIMARY INDICES & ALIASES
    A = arc_id
    N = node_id
    M = node_id
    P = product_id
    Q = product_id
    D = dem_id
    S = sup_id
    T = tech_id
    L = techsite_id

    ################################################################################
    ### SECONDARY INDICES (INTERSECTIONS OF PRIMARY INDICES)

    # Truth table for available arcs; nodes N and M are connected by A
    AnM = Dict() # given node n, provides all nodes m in M connected by an arc a in A
    Ain = Dict() # given node n, provides all arcs a in A directed towards node n
    Aout = Dict() # given node n, provides all arcs a in A directed out of node n
    [AnM[n] = Vector{String}(undef,0) for n in N]
    [Ain[n] = Vector{String}(undef,0) for n in N]
    [Aout[n] = Vector{String}(undef,0) for n in N]
    for a in A
        push!(AnM[arc_n[a]], arc_m[a])
        push!(Ain[arc_m[a]],a)
        push!(Aout[arc_n[a]],a)
    end

    # Mapping set: technology T uses product Q to produce product P
    TPQ = []
    for t in tech_id
        for p in tech_output[t]
            for q in tech_input[t]
                push!(TPQ,(t,p,q)) # (prod,ref) pairs
            end
        end
    end
    TPQ = unique(TPQ) # remove duplicates

    # Mapping set: node n produces product p from technology t (truth table and index list)
    NPT = DictInit([N,P,T],false)
    NPTlist = []
    # Mapping set: node n consumes product q for technology t (truth table and index list)
    NQT = DictInit([N,Q,T],false)
    NQTlist = []
    for ts in techsite_id
        n = techsite_node[ts] # element
        t = techsite_tech[ts] # element
        peas = tech_output[t] # list of elements
        ques = tech_input[t] # list of elements
        for p in peas
            NPT[n,p,t] = true
            push!(NPTlist,(n,p,t))
        end
        for q in ques
            NQT[n,q,t] = true
            push!(NQTlist,(n,q,t))
        end
    end

    # given (n,p) (i.e, an output p in P) provide all associated t in T
    NPt = Dict()
    for n in node_id
        for p in product_id
            teas = [] # empty list of t indices
            for t in tech_id
                if NPT[n,p,t] # is true
                    push!(teas,t)
                end
            end
            NPt[n,p] = teas
        end
    end
    # given (n,q) (i.e, an input q in Q) provide all associated t in T
    NQt = Dict()
    for n in node_id
        for q in product_id
            teas = [] # empty list of t indices
            for t in tech_id
                if NQT[n,q,t] # is true
                    push!(teas,t)
                end
            end
            NQt[n,q] = teas
        end
    end

    ################################################################################
    ### CALCULATED PARAMETERS 

    # Maximum demand by node and product
    dMAX = DictInit([N,P],0)
    for n in node_id
        for p in product_id
            for j in dem_id
                if dem_node[j] == n && dem_prod[j] == p
                    dMAX[n,p] += dem_cap[j]
                end
            end
        end
    end

    # Maximum supply by node and product
    sMAX = DictInit([N,P],0)
    for n in node_id
        for p in product_id
            for i in sup_id
                if sup_node[i] == n && sup_prod[i] == p
                    sMAX[n,p] += sup_cap[i]
                end
            end
        end
    end

    # yield of p from q in technology t
    α = Dict()
    for t in tech_id
        for p in tech_output[t] # list of products made by t
            for q in tech_input[t] # list of products consumed by t
                α[t,p,q] = tech_output_yields[t,p]/tech_input_yields[t,q]
            end
        end
    end

    # Maximum production levels
    ξgenMAX = DictInit([T,N,P],0)
    for ts in techsite_id # techsite produces (t,n) pairs
        for p in tech_output[techsite_tech[ts]] # list of output products from t
            ξgenMAX[techsite_tech[ts],techsite_node[ts],p] = tech_output_yields[techsite_tech[ts],p]*tech_cap[techsite_tech[ts]]
        end
    end

    ξconMAX = DictInit([T,N,Q],0)
    for ts in techsite_id # produces (t,n) pairs
        for q in tech_input[techsite_tech[ts]] # a list of product id's
            ξconMAX[techsite_tech[ts],techsite_node[ts],q] = tech_input_yields[techsite_tech[ts],q]*tech_cap[techsite_tech[ts]] # capacity for technology at ts
        end
    end

    # Maximum flow variable f
    fMAX = DictInit([A,P],0)
    for a in A
        for p in P
            fMAX[a,p] = arc_cap[a]
        end
    end

    ################################################################################
    ### SET UP CUSTOM STRUCTURES TO RETURN DATA

    # Structures for primary indices and data
    A = ArcDataStruct(arc_id,arc_n,arc_m,arc_cap,arc_len)
    N = NodeDataStruct(node_id,node_alias,node_lon,node_lat)
    P = ProductDataStruct(product_id,product_alias,product_trspt)
    D = DemandDataStruct(dem_id,dem_node,dem_prod,dem_bid,dem_cap)
    S = SupplyDataStruct(sup_id,sup_node,sup_prod,sup_bid,sup_cap)
    T = TechDataStruct(tech_id,tech_output,tech_input,tech_output_yields,tech_input_yields,tech_bid_ref,tech_bid,tech_cap,tech_defn)
    L = TechsiteDataStruct(techsite_id,techsite_node,techsite_tech)

    # Structures for secondary indices
    Sets = SetStruct(Ain,Aout,TPQ,NQT,NPt,NQt)

    # Structures for calculated parameters
    Pars = ParStruct(dMAX,sMAX,α,ξgenMAX,ξconMAX,fMAX)

    ################################################################################
    ### UPDATE USER
    println(PrintSpacer*"\nData Load Complete\n"*PrintSpacer)

    ################################################################################
    ### RETURN
    return(A,N,P,D,S,T,L,Sets,Pars);
    # e.g.: A,N,P,D,S,T,L,Sets,Pars = LoadSSCaseData("/Users/ptominac/Documents/Code/CoordinatedSupplyChains/TestCases/TestV36");
end