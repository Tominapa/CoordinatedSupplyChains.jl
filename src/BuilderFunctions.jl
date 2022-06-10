################################################################################
### DATA STRUCTURE BUILDING FUNCTIONS - NOT FOR CALLING BY USER

##############################
### Time
function TimeGen(time_id, time_dur)
    """
    Generates time data strucures
    Inputs:
        - time point IDs
        - time period durations
    Outputs:
        - time data structure (T)
        - sets T1, Tt, and TT (provide convenient reference sets)
        - sets Tprior and Tpost (provide references to prior and subsequent time points)
    """
    ### Part 0 - Setup
    CardT = length(time_id)

    ### Part 1 - Build time data structure
    T = TimeDataStruct(
        time_id, # ID
        time_dur # dt
    )

    ### Part 2 - Build time data indexing sets
    T1 = [time_id[1]] # first time point as a 1D array with length 1
    Tt = time_id[1:(end-1)] # all time points EXCEPT terminal time point
    TT = time_id[2:end] # all time points EXCEPT initial time point

    Tprior = Dict{String,String}()
    for t = 2:CardT
        Tprior[time_id[t]] = time_id[t-1]
    end

    Tpost = Dict{String,String}()
    for t = 1:(CardT-1)
        Tpost[time_id[t]] = time_id[t+1]
    end

    ### Return
    return T, T1, Tt, TT, Tprior, Tpost
end

# Nodes
function NodeGen(node_id, node_alias, node_lon, node_lat)
    """
    Generates node data strucures
    Inputs:
        - spatial node IDs
        - node names
        - node longitudes
        - node latitudes
    Outputs:
        - time data structure (T)
        - sets T1, Tt, and TT (provide convenient reference sets)
        - sets Tprior and Tpost (provide references to prior and subsequent time points)
    """
    ### Part 1 - Build node data structure
    N = NodeDataStruct(
        node_id, # ID
        node_alias, # alias
        node_lon, # lon
        node_lat # lat
    )

    ### Return
    return N
end

# Products
function ProductGen(product_id, product_alias, product_transport_cost, product_storage_cost)
    """
    Generates product data structure
    Inputs:
        - product IDs
        - product names
        - product transportation costs (i.e., spatial)
        - product storage costs (i.e., temporal)
    Outputs:
        - data structure (P)
    """
    ### Part 1 - Build product data structure
    P = ProductDataStruct(
        product_id, # ID
        product_alias, # alias
        product_transport_cost, # transport_cost
        product_storage_cost # storage_cost
    )

    ### Return
    return P
end

# Impacts
function ImpactGen(impact_id, impact_alias, impact_transport_coeff, impact_storage_coeff)
    """
    Generates product data structure
    Inputs:
        - impact IDs
        - impact names
        - impact transportation coefficients (i.e., spatial generation)
        - impact storage coefficients (i.e., temporal generation)
    Outputs:
        - data structure (Q)
    """
    ### Part 1 - Build impact data strucure
    Q = ImpactDataStruct(
        impact_id, # ID
        impact_alias, # alias
        impact_transport_coeff, # transport_coeff
        impact_storage_coeff # storage_coeff
    )

    ### Return
    return Q
end

# Arcs
function ArcGen(time_id, time_dur, node_id, product_id, product_transport_cost, product_storage_cost, arc_id, arc_n, arc_m, arc_cap, arc_len; M=1E6)
    """
    Generates arc data structures
    Inputs:
        - time node ids
        - time period durations
        - spatial node ids
        - spatial node positions (lon,lat)
        - product ids
        - spatial arc ids
        - spatial arc nodes (sending, receiving)
        - spatial arc capacities
    Outputs:
        - arc data structure (A)
        - set Ain; returns all arcs inbound on node n
        - set Aout; returns all arcs outbound from node n

    Update notes:
        - for now, assume FULL TIME CONNECTION
        - TO DO: add MODE keyword argument; allow full time connection or sequential time connection
    """
    ### Part 1 - Build Arc Data Structure
    # Calculate number of arcs to define
    CardA = 2*length(arc_id) # The number of geographical arcs defined; *2 because they define both directions
    CardN = length(node_id) # number of nodes
    CardT = length(time_id) # number of time points
    CardSTA = Int(0.5*CardA*CardT*(CardT+1) + 0.5*CardN*CardT*(CardT-1)) # number of spatio-temporal arcs

    # Number of digits in CardSTA; use in lpad()
    pad = ndigits(CardSTA)
        
    # Define arc set and declare data arrays
    STarc_id = Array{String}(undef, CardSTA) # Spatio-temporal (ST) arc IDs
    STarc_n_send = Array{String}(undef, CardSTA) # sending node
    STarc_n_recv = Array{String}(undef, CardSTA) # receiving node
    STarc_t_send = Array{String}(undef, CardSTA) # sending time point
    STarc_t_recv = Array{String}(undef, CardSTA) # receving time point
    STarc_cap_key = Array{String}(undef, CardSTA) # capacity key
    STarc_len = Dict() # length
    STarc_dur = Dict() # duration
    STarc_id_s = Array{String}(undef, 0) # list of purely spatial arcs
    STarc_id_t = Array{String}(undef, 0) # list of purely temporal arcs
    STarc_id_st = Array{String}(undef, 0) # list of spatio-temporal arcs

    # Define a counter to track STarc_id position
    global OrdSTA = 0 # ordinate within ST arc set

    # Add purely spatial arcs to STarc set
    for t = 1:CardT
        for a = 1:length(arc_id)
            # Index update
            global OrdSTA += 1

            # Add forward arc
            STarc_id[OrdSTA] = "A"*lpad(OrdSTA,pad,"0")
            STarc_n_send[OrdSTA] = arc_n[arc_id[a]]
            STarc_n_recv[OrdSTA] = arc_m[arc_id[a]]
            STarc_t_send[OrdSTA] = time_id[t]
            STarc_t_recv[OrdSTA] = time_id[t]
            STarc_cap_key[OrdSTA] = arc_id[a]
            STarc_len[STarc_id[OrdSTA]] = arc_len[arc_id[a]]
            STarc_dur[STarc_id[OrdSTA]] = 0.0
            push!(STarc_id_s, STarc_id[OrdSTA])

            # Index update
            global OrdSTA += 1

            # Add reverse arc
            STarc_id[OrdSTA] = "A"*lpad(OrdSTA,pad,"0")
            STarc_n_send[OrdSTA] = arc_m[arc_id[a]]
            STarc_n_recv[OrdSTA] = arc_n[arc_id[a]]
            STarc_t_send[OrdSTA] = time_id[t]
            STarc_t_recv[OrdSTA] = time_id[t]
            STarc_cap_key[OrdSTA] = arc_id[a]
            STarc_len[STarc_id[OrdSTA]] = arc_len[arc_id[a]]
            STarc_dur[STarc_id[OrdSTA]] = 0.0
            push!(STarc_id_s, STarc_id[OrdSTA])
        end
    end

    # Add purely temporal arcs to STarc set
    for t_send = 1:(CardT-1)
        for t_recv = (t_send+1):CardT
            for n = 1:length(node_id)
                # Index update
                global OrdSTA += 1

                # Add temporal arc connecting node to future time points
                STarc_id[OrdSTA] = "A"*lpad(OrdSTA,pad,"0")
                STarc_n_send[OrdSTA] = node_id[n]
                STarc_n_recv[OrdSTA] = node_id[n]
                STarc_t_send[OrdSTA] = time_id[t_send]
                STarc_t_recv[OrdSTA] = time_id[t_recv]
                STarc_cap_key[OrdSTA] = "M"
                STarc_len[STarc_id[OrdSTA]] = 0.0
                STarc_dur[STarc_id[OrdSTA]] = sum([time_dur[time_id[t]] for t = t_send:(t_recv-1)])
                push!(STarc_id_t, STarc_id[OrdSTA])
            end
        end
    end

    # Add spatio-temporal arcs to STarc set
    for t_send = 1:(CardT-1)
        for t_recv = (t_send+1):CardT
            for a = 1:length(arc_id)
                # Index update
                global OrdSTA += 1

                # Add n->m spatio-temporal arc
                STarc_id[OrdSTA] = "A"*lpad(OrdSTA,pad,"0")
                STarc_n_send[OrdSTA] = arc_n[arc_id[a]]
                STarc_n_recv[OrdSTA] = arc_m[arc_id[a]]
                STarc_t_send[OrdSTA] = time_id[t_send]
                STarc_t_recv[OrdSTA] = time_id[t_recv]
                STarc_cap_key[OrdSTA] = arc_id[a]
                STarc_len[STarc_id[OrdSTA]] = arc_len[arc_id[a]]
                STarc_dur[STarc_id[OrdSTA]] = sum([time_dur[time_id[t]] for t = t_send:(t_recv-1)])
                push!(STarc_id_st, STarc_id[OrdSTA])

                # Index update
                global OrdSTA += 1

                # Add m->n spatio-temporal arc
                STarc_id[OrdSTA] = "A"*lpad(OrdSTA,pad,"0")
                STarc_n_send[OrdSTA] = arc_m[arc_id[a]]
                STarc_n_recv[OrdSTA] = arc_n[arc_id[a]]
                STarc_t_send[OrdSTA] = time_id[t_send]
                STarc_t_recv[OrdSTA] = time_id[t_recv]
                STarc_cap_key[OrdSTA] = arc_id[a]
                STarc_len[STarc_id[OrdSTA]] = arc_len[arc_id[a]]
                STarc_dur[STarc_id[OrdSTA]] = sum([time_dur[time_id[t]] for t = t_send:(t_recv-1)])
                push!(STarc_id_st, STarc_id[OrdSTA])
            end
        end
    end

    # Build STarc bid dictionary
    STarc_bid = DictInit([STarc_id,product_id], 0.0)
    for a in STarc_id
        for p = product_id
            STarc_bid[a,p] = product_transport_cost[p]*STarc_len[a] + product_storage_cost[p]*STarc_dur[a]
        end
    end

    # Build STarc capacity dictionary
    STarc_cap = DictInit([STarc_id,product_id], 0.0)
    for a = 1:CardSTA
        for p = 1:length(product_id)
            if STarc_cap_key[a] == "M"
                # These are the purely temporal arcs; no connection to a physical arc, so use a big M value
                STarc_cap[STarc_id[a],product_id[p]] = M
            else
                # Apply geographic arc capacities to all arcs (spatio-temporal will have same)
                STarc_cap[STarc_id[a],product_id[p]] = arc_cap[STarc_cap_key[a],product_id[p]]
            end
        end
    end

    A = ArcDataStruct(STarc_id,
        Dict{String,String}(zip(STarc_id, STarc_n_send)), # sending nodes
        Dict{String,String}(zip(STarc_id, STarc_n_recv)), # receiving nodes
        Dict{String,String}(zip(STarc_id, STarc_t_send)), # sending times
        Dict{String,String}(zip(STarc_id, STarc_t_recv)), # receiving times
        STarc_bid, # bids by product
        STarc_cap, # capacities by product
        STarc_len, # lengths
        STarc_dur, # durations
        STarc_id_s, # spatial arcs
        STarc_id_t, # temporal arcs
        STarc_id_st # spatio-temporal arcs
    )

    ### Part 2 - Build Arc Truth Tables
    # Ain and Aout
    Ain = Dict() # given node s(n,t), provides all arcs a in A directed towards node s
    Aout = Dict() # given node s(n,t), provides all arcs a in A directed out of node s
    [Ain[n,t] = Vector{String}(undef,0) for n in node_id, t in time_id]
    [Aout[n,t] = Vector{String}(undef,0) for n in node_id, t in time_id]
    for a = 1:CardSTA
        push!(Ain[STarc_n_recv[a], STarc_t_recv[a]], STarc_id[a])
        push!(Aout[STarc_n_send[a], STarc_t_send[a]], STarc_id[a])
    end

    ### Return
    return A, Ain, Aout
end

# Demand
function DemandGen(demand_id, demand_node, demand_time, demand_prod, demand_bid, demand_cap, demand_impact, demand_impact_yield)
    """
    Generates node data strucures
    Inputs:
        - demand IDs
        - demand nodes
        - demand time periods
        - demand products
        - demand bids
        - demand capacities
        - demand impacts
        - demand impact yields
    Outputs:
        - demand data structure (D)
    """
    ### Part 1 - Build demand data structure
    D = DemandDataStruct(
        demand_id, # ID
        demand_node, # node
        demand_time, # time
        demand_prod, # prod
        demand_bid, # bid
        demand_cap, # cap
        demand_impact, # impacts
        demand_impact_yield #impact yield cooefficients
    )

    ### Return
    return D
end

# Supply
function SupplyGen(supply_id, supply_node, supply_time, supply_prod, supply_bid, supply_cap, supply_impact, supply_impact_yeild)
    """
    Generates supply data strucures
    Inputs:
        - supply IDs
        - supply node
        - supply time period
        - supply product
        - supply bid
        - supply capacity
        - supply impacts
        - supply impact yields
    Outputs:
        - supply data structure (G)
    """
    ### Part 1 - Build supply data structure
    G = SupplyDataStruct(
        supply_id, # ID
        supply_node, # node
        supply_time, # time
        supply_prod, # prod
        supply_bid, # bid
        supply_cap, # cap
        supply_impact, # impacts
        supply_impact_yeild # supply impact yield coefficients
    )

    ### Return
    return G
end

# Environmental stakeholder
function EnvGen(env_id, env_node, env_time, env_impact, env_bid, env_cap)
    """
    Generates environmental stakeholder data strucures
    Inputs:
        - env IDs
        - env node
        - env time period
        - env impact
        - env bid
        - env cap
    Outputs:
        - env data structure (V)
    """
    ### Part 1 - Build environmental stakeholder data structure
    V = EnvDataStruct(
        env_id, # ID
        env_node, # node
        env_time, # time
        env_impact, # impact
        env_bid, # bid
        env_cap # capacity
    )

    ### Return
    return V
end

# Technologies
function TechGen(tech_id, tech_output, tech_input, tech_impact, tech_output_yield, tech_input_yield, tech_impact_yield, tech_ref, tech_bid, tech_cap, tech_alias)
    """
    Generates technology data strucures
    Inputs:
        - technology IDs
        - technology outputs
        - technology inputs
        - technology impacts
        - technology output yields
        - technology input yields
        - technology impact yields
        - technology reference product
        - technology bid
        - technology capacity
        - technology alias
    Outputs:
        - technology data structure (M)
        - technology index set MPQ (commented, for now as uneeded)
    """
    ### Part 1 - buiild technology data structure
    M = TechDataStruct(
        tech_id, # ID
        tech_output, # Outputs
        tech_input, # Inputs
        tech_impact, # Impacts
        tech_output_yield, # OutputYields
        tech_input_yield, # InputYields
        tech_impact_yield, # ImpactYields
        tech_ref, # InputRef
        tech_bid, # bid
        tech_cap, # cap
        tech_alias # alias
    )
    
    ### Return
    return M
end

# Technology mapping
function TechMapGen(techmap_id, techmap_node, techmap_time, techmap_tech)
    """
    Generates technology mapping data strucures
    Inputs:
        - technology mapping IDs
        - technology map nodes
        - technology map times
        - technology map technology IDs
    Outputs:
        - techmap data structure (L)
    """
    ### Part 1 - build technology map data structure
    L = TechmapDataStruct(
        techmap_id, # ID
        techmap_node, # node
        techmap_time, # time
        techmap_tech # tech
    )
    ### Return
    return L
end

# Supplier mapping
function SupplyIndexGen(node_id,time_id,product_id,supply_id,supply_node,supply_time,supply_prod)
    """
    Generates supplier index set mapping i∈G to n∈N,t∈T,p∈P
    Inputs:
        - node IDs
        - time IDs
        - product IDs
        - supplier IDs
        - supplier nodes
        - supplier times
        - supplier products
    Outputs:
        - Supplier indexing set Gntp
    """
    Gntp = DictListInit([node_id,time_id,product_id],InitStringArray)
    for i in supply_id
        n = supply_node[i]
        t = supply_time[i]
        p = supply_prod[i]
        push!(Gntp[n,t,p], i)
    end
    return Gntp
end

# Consumer mapping
function DemandIndexGen(node_id,time_id,product_id,demand_id,demand_node,demand_time,demand_prod)
    """
    Generates consumer index set mapping j∈D to n∈N,t∈T,p∈P
    Inputs:
        - node IDs
        - time IDs
        - product IDs
        - consumer IDs
        - consumer nodes
        - consumer times
        - consumer products
    Outputs:
        - Consumer indexing set Dntp
    """
    Dntp = DictListInit([node_id,time_id,product_id],InitStringArray)
    for j in demand_id
        n = demand_node[j]
        t = demand_time[j]
        p = demand_prod[j]
        push!(Dntp[n,t,p], j)
    end
    return Dntp
end

# Environmental consumer mapping
function EnvIndexGen(node_id,time_id,impact_id,supply_id,supply_node,supply_time,supply_impact,demand_id,demand_node,demand_time,demand_impact,env_id,env_node,env_time,env_impact)
    """
    Generates environmental consumer index set mapping v∈V to n∈N,t∈T,q∈Q
    Inputs:
        - node IDs
        - time IDs
        - impact IDs
        - supplier IDs
        - supplier nodes
        - supplier times
        - supplier impacts
        - consumer IDs
        - consumer nodes
        - consumer times
        - consumer impacts
        - env. consumer IDs
        - env. consumer nodes
        - env. consumer times
        - env. consumer impacts
    Outputs:
        - Supplier indexing set Gntq
        - Consumer indexing set Dntq
        - Env. consumer indexing set Vntq
    """
    Gntq = DictListInit([node_id,time_id,impact_id],InitStringArray)
    for i in supply_id
        ques = supply_impact[i]
        if ques != [""] # allow impactless suppliers; they are just not included in this set
            n = supply_node[i]
            t = supply_time[i]
            for q in ques
                push!(Gntq[n,t,q], i)
            end
        end
    end

    Dntq = DictListInit([node_id,time_id,impact_id],InitStringArray)
    for j in demand_id
        ques = demand_impact[j]
        if ques != [""] # allow impactless consumers; they are just not included in this set
            n = demand_node[j]
            t = demand_time[j]
            for q in ques
                push!(Dntq[n,t,q], j)
            end
        end
    end

    Vntq = DictListInit([node_id,time_id,impact_id],InitStringArray)
    for v in env_id
        n = env_node[v]
        t = env_time[v]
        q = env_impact[v]
        push!(Vntq[n,t,q], v)
    end
    return Gntq, Dntq, Vntq
end

# Subset for suppliers with impacts
function SuppliersWithImpacts(supply_id, supply_impact)
    """
    Generates subset of suppliers i ∈ G with associated impacts q in Q != ϕ
    Inputs:
        - supplier IDs
        - supplier impacts
    Outputs:
        - Set of suppliers with environmental impacts, GQ
    """
    GQ = []
    for i in supply_id
        if supply_impact[i] != [""]
            push!(GQ, i)
        end
    end
    return GQ
end

# Subset for consumers with impacts
function ConsumersWithImpacts(demand_id, demand_impact)
    """
    Generates subset of consumers j ∈ D with associated impacts q in Q != ϕ
    Inputs:
        - consumer IDs
        - consumer impacts
    Outputs:
        - Set of consumers with environmental impacts, DQ
    """
    DQ = []
    for j in demand_id
        if demand_impact[j] != [""]
            push!(DQ, j)
        end
    end
    return DQ
end

# Technology input/output mapping index sets
function TechProductIndexSetGen(node_id, time_id, product_id, tech_output, tech_input, techmap_id, techmap_node, techmap_time, techmap_tech)
    """
    Generates technology mapping data strucures
    Inputs:
        - node IDs
        - time point IDs
        - product IDs
        - technology inputs
        - technology outputs
        - techmap IDs
        - techmap nodes
        - techmap times
        - techmap technology types
    Outputs:
        - Index sets NTPgenl and NTPconl for product output/input
    """
    ### Part 1 - Product output/input index sets
    # Index set, given (n,t,p) provide all l ∈ L satisfying n(l)=n,t(l)=t,p∈tech_output[m(l)]
    NTPgenl = DictListInit([node_id,time_id,product_id], InitStringArray)
    # Index set, given (n,t,p) provide all l ∈ L satisfying n(l)=n,t(l)=t,p∈tech_input[m(l)]
    NTPconl = DictListInit([node_id,time_id,product_id], InitStringArray)
    for l in techmap_id
        m = techmap_tech[l]
        n = techmap_node[l]
        t = techmap_time[l]
        for p in tech_output[m]
            push!(NTPgenl[n,t,p], l)
        end
        for p in tech_input[m]
            push!(NTPconl[n,t,p], l)
        end
    end

    ### Return
    return NTPgenl, NTPconl
end

# Technology input/output mapping index sets
function TechImpactIndexSetGen(node_id, time_id, impact_id, tech_impact, techmap_id, techmap_node, techmap_time, techmap_tech)
    """
    Generates technology mapping data strucures
    Inputs:
        - node IDs
        - time point IDs
        - impact IDs
        - technology impacts
        - techmap IDs
        - techmap nodes
        - techmap times
        - techmap technology types
    Outputs:
        - Index set NTQgenl for impact generation
    """
    ### Part 1 - Product output/input index sets
    # Index set, given (n,t,q) provide all l ∈ L satisfying n(l)=n,t(l)=t,q∈tech_impact[m(l)]
    NTQgenl = DictListInit([node_id,time_id,impact_id], InitStringArray)
    for l in techmap_id
        m = techmap_tech[l]
        n = techmap_node[l]
        t = techmap_time[l]
        for q in tech_impact[m]
            push!(NTQgenl[n,t,q], l)
        end
    end

    ### Return
    return NTQgenl
end

### Parameter generation functions
function par_gMAX(node_id,time_id,product_id,supply_id,supply_node,supply_time,supply_prod,supply_cap)
    ### nodal supply capacity
    gMAX = DictInit([node_id,time_id,product_id], 0.0)
    for n in node_id
        for t in time_id
            for p in product_id
                for i in supply_id
                    if supply_node[i] == n && supply_time[i] == t && supply_prod[i] == p
                        gMAX[n,t,p] += supply_cap[i]
                    end
                end
            end
        end
    end
    return gMAX
end

function par_dMAX(node_id,time_id,product_id,demand_id,demand_node,demand_time,demand_prod,demand_cap)
    ### nodal demand capacity
    dMAX = DictInit([node_id,time_id,product_id], 0.0)
    for n in node_id
        for t in time_id
            for p in product_id
                for j in demand_id
                    if demand_node[j] == n && demand_time[j] == t && demand_prod[j] == p
                        dMAX[n,t,p] += demand_cap[j]
                    end
                end
            end
        end
    end
    return dMAX
end

function par_eMAX(node_id,time_id,impact_id,env_id,env_node,env_time,env_impact,env_cap)
    ### nodal impact capacity
    eMAX = DictInit([node_id,time_id,impact_id], 0.0)
    for n in node_id
        for t in time_id
            for q in impact_id
                for v in env_id
                    if env_node[v] == n && env_time[v] == t && env_impact[v] == q
                        eMAX[n,t,q] += env_cap[v]
                    end
                end
            end
        end
    end
    return eMAX
end

function par_γiq(GQ,supply_impact,supply_impact_yield)
    ### yield of impact q from supplier i
    γiq = Dict()
    for i in GQ
        for q in supply_impact[i] # list of impacts q generated by supplying i
            γiq[i,q] = supply_impact_yield[i,q]
        end
    end
    return γiq
end

function par_γjq(DQ,demand_impact,demand_impact_yield)
    ### yield of impact q from consumer j
    γjq = Dict()
    for j in DQ
        for q in demand_impact[j] # list of impacts q generated by consuming j
            γjq[j,q] = demand_impact_yield[j,q]
        end
    end
    return γjq
end

function par_γaq(arc_id,impact_id,arc_len,arc_dur,impact_transport_coeff,impact_storage_coeff)
    ### yield of impact q from transport across arc a
    γaq = Dict()
    for a in arc_id
        for q in impact_id
            # includes both spatial and temporal dimensions
            # from model implementation: (Q.transport_coeff[q]*A.len[a] + Q.storage_coeff[q]*A.dur[a])
            γaq[a,q] = impact_transport_coeff[q]*arc_len[a] + impact_storage_coeff[q]*arc_dur[a]
        end
    end
    return γaq
end

function par_γmp(tech_id,tech_output,tech_input,tech_output_yield,tech_input_yield)
    ### yield of product p in technology m
    γmp = Dict()
    for m in tech_id
        for p_gen in tech_output[m] # list of products made by m
            γmp[m,p_gen] = tech_output_yield[m,p_gen]
        end
        for p_con in tech_input[m] # list of products consumed by m
            γmp[m,p_con] = tech_input_yield[m,p_con]
        end
    end
    return γmp
end

function par_γmq(tech_id,tech_impact,tech_impact_yield)
    ### yield of impact q from technology m
    γmq = Dict() # yield of i from q in technology t
    for m in tech_id
        for q in tech_impact[m]
            γmq[m,q] = tech_impact_yield[m,q]# == tech_impact_stoich[m,q]/tech_input_stoich[m,pref]
        end
    end
    return γmq
end

function par_ξgenMAX(techmap_id,techmap_tech,product_id,tech_output,tech_output_yield,tech_cap)
    ### Maximum production levels
    #ξgenMAX = DictInit([tech_id,node_id,time_id,product_id],0.0)
    ξgenMAX = DictInit([techmap_id,product_id],0.0)
    for l in techmap_id
        m = techmap_tech[l]
        for p in tech_output[m]
            ξgenMAX[l,p] = tech_output_yield[m,p]*tech_cap[m]
        end
    end
    return ξgenMAX
end

function par_ξconMAX(techmap_id,techmap_tech,product_id,tech_input,tech_input_yield,tech_cap)
    ### Maximum consumption levels
    #ξconMAX = DictInit([tech_id,node_id,time_id,product_id],0.0)
    ξconMAX = DictInit([techmap_id,product_id],0.0)
    for l in techmap_id
        m = techmap_tech[l]
        for p in tech_input[m]
            ξconMAX[l,p] = tech_input_yield[m,p]*tech_cap[m]
        end
    end
    return ξconMAX
end

function par_ξenvMAX(techmap_id,techmap_tech,impact_id,tech_impact,tech_impact_yield,tech_cap)
    ### Maximum impact generation levels
    #ξenvMAX = DictInit([tech_id,node_id,time_id,impact_id],0.0)
    ξenvMAX = DictInit([techmap_id,impact_id],0.0)
    for l in techmap_id
        m = techmap_tech[l]
        for q in tech_impact[m]
            ξenvMAX[l,q] = tech_impact_yield[m,q]*tech_cap[m]
        end
    end
    return ξenvMAX
end