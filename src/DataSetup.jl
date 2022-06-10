################################################################################
### IMPORT DATA AND BUILD DATA STRUCTURES
function BuildModelData(DataDir,UseArcLengths)
    """
    Imports source data from given folder and builds model data structures

    Inputs:
    -> DataDir: a directory to a folder containing model data

    Returns:
    -> T: struct for time data
    -> N: struct for node data
    -> P: struct for product data
    -> Q: struct for impact data
    -> A: struct for arc data
    -> D: struct for demand data
    -> S: struct for supply data
    -> V: struct for environmental consumer data
    -> M: struct for technology data
    -> L: struct for technology mapping data
    -> Subsets: struct containing subsets and inersection sets of the above
    -> Pars: struct containing calculated parameters
    """

    ################################################################################
    ### DATA SETUP
    ### Time data parsing
    time_data = try
        readdlm(joinpath(DataDir,"csvdata_time.csv"),',',Any,comments=true) # import csv data
    catch
        false
    end
    UseTime = true # assume time data exists by default
    if time_data == false
        UseTime = false
        time_id = ["T0"]
        time_dur = Dict(time_id[1] => 0.0)
    else
        time_id = convert(Array{String}, time_data[:, 1])
        time_dur = Dict{String,Float64}(zip(time_id, convert(Array{Float64}, time_data[:, 2]))) # duration
    end

    ### Node data parsing
    node_data = readdlm(joinpath(DataDir,"csvdata_node.csv"),',',Any,comments=true) # import csv data
    node_id = convert(Array{String}, node_data[:, 1])
    node_alias = Dict{String,String}(zip(node_id, node_data[:, 2])) # node name
    node_lon = Dict{String,Float64}(zip(node_id, convert(Array{Float64}, node_data[:, 3]))) # longitude
    node_lat  = Dict{String,Float64}(zip(node_id, convert(Array{Float64}, node_data[:, 4]))) # latitude

    ### Product data parsing
    product_data = readdlm(joinpath(DataDir,"csvdata_product.csv"),',',Any,comments=true) # import csv data
    product_id = convert(Array{String}, product_data[:, 1])
    product_alias = Dict{String,String}(zip(product_id, convert(Array{String}, product_data[:, 2]))) # product name
    product_transport_cost = Dict{String,Float64}(zip(product_id, product_data[:, 3])) # product transport cost
    product_storage_cost = Dict{String,Float64}(zip(product_id, product_data[:, 4])) # product storage cost

    ### Impact data parsing
    impact_data = try
        readdlm(joinpath(DataDir,"csvdata_impact.csv"),',',Any,comments=true) # import csv data
    catch
        false # assign false just to get out of try/catch
    end
    # Control flow for scenario in which no impact data is provided
    UseImpacts = true # assume there will be impact data by default
    if impact_data == false
        UseImpacts = false # use UseImpacts as the control flow condition in main code
    end
    if UseImpacts # Parse impact data if it is defined
        impact_id = convert(Array{String}, impact_data[:, 1])
        impact_alias = Dict{String,String}(zip(impact_id, convert(Array{String}, impact_data[:, 2]))) # impact name & units
        impact_transport_coeff = Dict{String,Float64}(zip(impact_id, impact_data[:, 3])) # impact production during transport
        impact_storage_coeff = Dict{String,Float64}(zip(impact_id, impact_data[:, 4])) # impact production during storage
    else
        impact_id = []
        impact_alias = Dict() # impact name & units
        impact_transport_coeff = Dict() # impact production during transport
        impact_storage_coeff = Dict() # impact production during storage
    end

    ### Arc data parsing
    arc_data = try
        readdlm(joinpath(DataDir,"csvdata_arcs.csv"),',',Any,comments=true) # import csv data
    catch
        false # assign false just to get out of try/catch
    end
    # Control flow for scenario in which no arc data is provided
    UseArcs = true # assume there will be technology data by default
    if arc_data == false
        UseArcs = false # use UseArcs as the control flow condition in main code
    end
    if UseArcs # Parse arc data if it is defined
        arc_id = convert(Array{String}, arc_data[:, 1])
        arc_n = Dict{String,String}(zip(arc_id, arc_data[:, 2])) # sending node "n"
        arc_m  = Dict{String,String}(zip(arc_id, arc_data[:, 3])) # receiving node "m"
        arc_cap  = NumericListFromCSV(arc_id, product_id, arc_data[:, 4]) # arc capacities, by product
        if UseArcLengths
            arc_len = Dict{String,Float64}(zip(arc_id, arc_data[:, 5])) # custom arc length
        else # i.e., calculate great circle arc lengths
            ref_lons = zeros(length(arc_id))
            ref_lats = zeros(length(arc_id))
            dest_lons = zeros(length(arc_id))
            dest_lats = zeros(length(arc_id))
            for a = 1:length(arc_id)
                ref_lons[a] = node_lon[arc_data[a, 2]]
                ref_lats[a] = node_lat[arc_data[a, 2]]
                dest_lons[a] = node_lon[arc_data[a, 3]]
                dest_lats[a] = node_lat[arc_data[a, 3]]
            end
            arc_len = Dict{String,Float64}(zip(arc_id,GreatCircle(ref_lons, ref_lats, dest_lons, dest_lats)))
        end
    else
        arc_id = []
        arc_n = Dict() # sending node "n"
        arc_m  = Dict() # receiving node "m"
        arc_cap  = Dict() # arc capacities, by product
        arc_len = Dict() # custom arc length
    end
    if !UseArcs && length(node_id) > 1
        println("*"^10*"  WARNING  "*"*"^10)
        println("There is more than one NODE entry, but no ARC data is detected!")
        println("Check your data and make sure everything is as intended.")
        println("Code will proceed.")
        println("*"^31)
    end

    ### Demand data parsing
    demand_data = readdlm(joinpath(DataDir,"csvdata_demand.csv"),',',Any,comments=true) # import csv data
    demand_id = convert(Array{String}, demand_data[:, 1])
    demand_node = Dict{String,String}(zip(demand_id, demand_data[:, 2])) # demand node
    if UseTime
        demand_time = Dict{String,String}(zip(demand_id, demand_data[:, 3])) # demand time
    else
        demand_time = Dict{String,String}(zip(demand_id, repeat(time_id,length(demand_id)))) # demand time
    end
    demand_prod = Dict{String,String}(zip(demand_id, demand_data[:, 4])) # demand product
    demand_bid = Dict{String,Float64}(zip(demand_id, demand_data[:, 5])) # demand bid
    demand_cap = Dict{String,Float64}(zip(demand_id, demand_data[:, 6])) # demand capacity
    demand_impact = PurgeQuotes(TextListFromCSV(demand_id, demand_data[:,7])) # demand impacts
    demand_impact_yield = NumericListFromCSV(demand_id, demand_impact, demand_data[:, 8]) # demand impact yield factors

    ### Supply data parsing
    supply_data = readdlm(joinpath(DataDir,"csvdata_supply.csv"),',',Any,comments=true)
    supply_id = convert(Array{String}, supply_data[:, 1])
    supply_node = Dict{String,String}(zip(supply_id, supply_data[:, 2])) # supply node
    if UseTime
        supply_time = Dict{String,String}(zip(supply_id, supply_data[:, 3])) # supply time
    else
        supply_time = Dict{String,String}(zip(supply_id, repeat(time_id,length(supply_id)))) # supply time
    end
    supply_prod = Dict{String,String}(zip(supply_id, supply_data[:, 4])) # supply product
    supply_bid = Dict{String,Float64}(zip(supply_id, supply_data[:, 5])) # supply bid
    supply_cap = Dict{String,Float64}(zip(supply_id, supply_data[:, 6])) # supply capacity
    supply_impact = PurgeQuotes(TextListFromCSV(supply_id, supply_data[:,7])) # supply impacts
    supply_impact_yield = NumericListFromCSV(supply_id, supply_impact, supply_data[:, 8]) # supply impact yield factors

    ### Environmental stakeholder data parsing
    if UseImpacts # if impacts are undefined, definitely don't need impact consumption data
        env_data = readdlm(joinpath(DataDir,"csvdata_env.csv"),',',Any,comments=true) # import csv data
        env_id = convert(Array{String}, env_data[:, 1])
        env_node = Dict{String,String}(zip(env_id, env_data[:, 2])) # environmental node
        if UseTime
            env_time = Dict{String,String}(zip(env_id, env_data[:, 3])) # environmental time
        else
            env_time = Dict{String,String}(zip(env_id, repeat(time_id,length(env_id)))) # environmental time
        end
        env_impact = Dict{String,String}(zip(env_id, env_data[:, 4])) # environmental product
        env_bid = Dict{String,Float64}(zip(env_id, env_data[:, 5])) # environmental bid
        env_cap = Dict{String,Float64}(zip(env_id, env_data[:, 6])) # environmental capacity (Inf, in most cases)
    else
        env_id = []
        env_node = Dict() # environmental node
        env_time = Dict() # environmental time
        env_impact = Dict() # environmental product
        env_bid = Dict() # environmental bid
        env_cap = Dict() # environmental capacity (Inf, in most cases)
    end

    ### Technology data parsing
    tech_data = try
        readdlm(joinpath(DataDir,"csvdata_tech.csv"),',',Any,comments=true) # import csv data
    catch
        false # assign false just to get out of try/catch
    end
    # Control flow for scenario in which no technology data is provided
    UseTechs = true # assume there will be technology data by default
    if tech_data == false
        UseTechs = false # use UseTechs as the control flow condition in main code
    end
    if UseTechs # Parse technology data if it is defined
        tech_id = convert(Array{String}, tech_data[:, 1])
        tech_output = TextListFromCSV(tech_id, tech_data[:,2]) # technology outputs
        tech_input = TextListFromCSV(tech_id, tech_data[:,3]) # technology inputs
        tech_impact = PurgeQuotes(TextListFromCSV(tech_id, tech_data[:,4])) # technology impacts
        tech_output_yield = NumericListFromCSV(tech_id, tech_output, tech_data[:, 5]) # product yield factors
        tech_input_yield = NumericListFromCSV(tech_id, tech_input, tech_data[:, 6]) # product yield factors
        tech_impact_yield = NumericListFromCSV(tech_id, tech_impact, tech_data[:, 7]) # impact yield factors
        tech_ref = Dict(zip(tech_id, tech_data[:, 8])) # reference product
        tech_bid = Dict(zip(tech_id, tech_data[:, 9])) # technology bid (operating cost)
        tech_cap = Dict(zip(tech_id, tech_data[:, 10])) # technology capacity (per time unit)
        tech_alias = Dict(zip(tech_id, tech_data[:, 11])) # technology alias

        # Technology mapping data parsing
        techmap_data = readdlm(joinpath(DataDir,"csvdata_techmap.csv"),',',Any,comments=true) # import csv data
        techmap_id = convert(Array{String}, techmap_data[:, 1])
        techmap_node = Dict(zip(techmap_id, techmap_data[:, 2])) # technology node (location)
        if UseTime
            techmap_time = Dict(zip(techmap_id, techmap_data[:, 3])) # technology time (availability)
        else
            techmap_time = Dict(zip(techmap_id, repeat(time_id,length(techmap_id)))) # technology time (availability)
        end
        techmap_tech = Dict(zip(techmap_id, techmap_data[:, 4])) # technology type (from tech_id)
    else
        tech_id = []
        tech_output = Dict() # technology outputs
        tech_input = Dict() # technology inputs
        tech_impact = Dict() # technology impacts
        tech_output_yield = Dict() # product yield factors
        tech_input_yield = Dict() # product yield factors
        tech_impact_yield = Dict() # impact yield factors
        tech_ref = Dict() # reference product
        tech_bid = Dict() # technology bid (operating cost)
        tech_cap = Dict() # technology capacity (per time unit)
        tech_alias = Dict() # technology alias

        # Technology mapping data parsing
        techmap_id = []
        techmap_node = Dict() # technology node (location)
        techmap_time = Dict() # technology time (availability)
        techmap_tech = Dict() # technology type (from tech_id)
    end

    ################################################################################
    ### GENERATE INDEX SETS
    # temporal data structure
    T, T1, Tt, TT, Tprior, Tpost = TimeGen(time_id, time_dur)

    # spatial data strucure
    N = NodeGen(node_id, node_alias, node_lon, node_lat)

    # product data structure
    P = ProductGen(product_id, product_alias, product_transport_cost, product_storage_cost)

    # impact data structure
    Q = ImpactGen(impact_id, impact_alias, impact_transport_coeff, impact_storage_coeff)

    # spatio-temporal arc set from geographical arc data
    A, Ain, Aout = ArcGen(time_id, time_dur, node_id, product_id, product_transport_cost, product_storage_cost, arc_id, arc_n, arc_m, arc_cap, arc_len)

    # demand data structure
    D = DemandGen(demand_id, demand_node, demand_time, demand_prod, demand_bid, demand_cap, demand_impact, demand_impact_yield)
    Dntp = DemandIndexGen(node_id,time_id,product_id,demand_id,demand_node,demand_time,demand_prod)
    DQ = ConsumersWithImpacts(demand_id, demand_impact)

    # supply data structure
    G = SupplyGen(supply_id, supply_node, supply_time, supply_prod, supply_bid, supply_cap, supply_impact, supply_impact_yield)
    Gntp = SupplyIndexGen(node_id,time_id,product_id,supply_id,supply_node,supply_time,supply_prod)
    GQ = SuppliersWithImpacts(supply_id, supply_impact)

    # environmental data structure
    V = EnvGen(env_id, env_node, env_time, env_impact, env_bid, env_cap)
    Gntq, Dntq, Vntq = EnvIndexGen(node_id,time_id,impact_id,supply_id,supply_node,supply_time,supply_impact,demand_id,demand_node,demand_time,demand_impact,env_id,env_node,env_time,env_impact)

    # technology data structure
    M = TechGen(tech_id, tech_output, tech_input, tech_impact, tech_output_yield, tech_input_yield, tech_impact_yield, tech_ref, tech_bid, tech_cap, tech_alias)
    # technology mapping data structure
    L = TechMapGen(techmap_id, techmap_node, techmap_time, techmap_tech)
    # technology indexing set generation
    NTPgenl, NTPconl = TechProductIndexSetGen(node_id, time_id, product_id, tech_output, tech_input, techmap_id, techmap_node, techmap_time, techmap_tech)
    NTQgenl = TechImpactIndexSetGen(node_id, time_id, impact_id, tech_impact, techmap_id, techmap_node, techmap_time, techmap_tech)

    ################################################################################
    ### GROUP SETS INTO STRUCT
    #= NOTE: sets are generated in the functions above because it seems to pass data
    back and forth fewer times. This may or may not be the correct interpreation.
    Consider testing it out at some point; there are likely efficiencies to be found =#
    Subsets = SetStruct(T1, Tt, TT, Tprior, Tpost, Ain, Aout, Dntp, Gntp, Dntq, Gntq, Vntq, DQ, GQ, NTPgenl, NTPconl, NTQgenl)

    ################################################################################
    ### GENERATE CALCULATED PARAMETERS
    # For code readability, break down by parameter; depricate old single-function approach
    gMAX = par_gMAX(node_id,time_id,product_id,supply_id,supply_node,supply_time,supply_prod,supply_cap)
    dMAX = par_dMAX(node_id,time_id,product_id,demand_id,demand_node,demand_time,demand_prod,demand_cap)
    eMAX = par_eMAX(node_id,time_id,impact_id,env_id,env_node,env_time,env_impact,env_cap)
    γiq = par_γiq(GQ,supply_impact,supply_impact_yield)
    γjq = par_γjq(DQ,demand_impact,demand_impact_yield)
    γaq = par_γaq(A.ID,impact_id,A.len,A.dur,impact_transport_coeff,impact_storage_coeff)
    γmp = par_γmp(tech_id,tech_output,tech_input,tech_output_yield,tech_input_yield)
    γmq = par_γmq(tech_id,tech_impact,tech_impact_yield)
    ξgenMAX = par_ξgenMAX(techmap_id,techmap_tech,product_id,tech_output,tech_output_yield,tech_cap)
    ξconMAX = par_ξconMAX(techmap_id,techmap_tech,product_id,tech_input,tech_input_yield,tech_cap)
    ξenvMAX = par_ξenvMAX(techmap_id,techmap_tech,impact_id,tech_impact,tech_impact_yield,tech_cap)
    
    # Build parameter structure with required data or nothing entries
    Pars = ParStruct(gMAX, dMAX, eMAX, γiq, γjq, γaq, γmp, γmq, ξgenMAX, ξconMAX, ξenvMAX)

    ################################################################################
    ### POPULATE CONTROL FLOW STRUCTURE
    CF = DataCF(UseTime,UseArcs,UseTechs,UseImpacts)

    ################################################################################
    ### RETURN
    return T, N, P, Q, A, D, G, V, M, L, Subsets, Pars, CF
end