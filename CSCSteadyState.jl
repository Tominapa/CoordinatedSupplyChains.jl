################################################################################
### JULIA PACKAGE IMPORTS ###
using JuMP
using Gurobi
using DelimitedFiles

#******************************************************************************#
#********** FILE OPTIONS, FOLDER PATHWAYS, AND HARD-CODED PARAMETERS **********#
#******************************************************************************#
################################################################################
### NOTES ###
#=
include("CSCSteadyState.jl")
=#
################################################################################
### FILE OPTIONS ###
# Print the model in the REPL? (Note: model is always output as a text file.)
PrintModel = false

# Print output to REPL? (Note: model output is always printed to text file.)
PrintOutput = true

# Specify separator text for printing
const PrintSpacer = "*"^50

# Use custom arc lengths or determine from longitude/latitude coordinates?
CustomLengths = false

################################################################################
### SET DIRECTORY ###
# This is where the model file is stored
#ModelDirectory = "/Users/ptominac/Documents/Code/CoordinatedSupplyChains"
#cd(ModelDirectory)

# Where data files are stored; presumably a folder in ModelDirectory
DataFolder = "TestCases/TestV36"

# Output model file name
ModelOutputFileName = "_Model.txt"

# Output solution data file name
SolutionOutputFileName = "_SolutionData.txt"

################################################################################
### PARAMETERIZED VALUES ###
const R = 6335.439 # Earth radius used for distance calculation

#******************************************************************************#
#******************************************************************************#
#******************************************************************************#

################################################################################
### USER FUNCTIONS ###
function GreatCircle(ref_lon, ref_lat, dest_lon, dest_lat)
    """
    Calculates the great circle distance between a reference location (ref)
    and a destination (dest) and returns the great circle distances in km
    """
    # haversine formula
    dist = 2*R*asin(sqrt(((sind((dest_lat - ref_lat)/2))^2) +
        cosd(dest_lat)*cosd(ref_lat)*((sind((dest_lon - ref_lon)/2))^2)))
    return(dist)
end

function TextListFromCSV(IDs,DataCol)
    """
    This function recovers comma-separated lists of text labels stored as
    single entries in a csv file (separated by a non-comma separator) and
    returns them as a dictionary indexed by the given IDs
    i.e., |P01,P02,P03| -> ["P01","P02","P03"]
    Inputs:
        IDs - a list of labels to be used as dictionary keys
        DataCol - The column of data with rows corresponding to the labels in
            IDS, with each containing one or more text labels separated by commas
    Outputs:
        Out - a dictionary mapping the keys in IDs to the values in DataCol

    Note: This function replaces code of the form:
    for s = 1:length(asset_id) # AssetData[s,4] is a comma-separated list
        asset_inputs[asset_id[s]] = [String(i) for i in split(AssetData[s,4],",")]
    end
    """
    Out = Dict()
    for i = 1:length(IDs)
        Out[IDs[i]] = [String(i) for i in split(DataCol[i],",")]
    end
    return Out
end

function NumericListFromCSV(IDs,ID2s,DataCol)
    """
    For data that may be stored as a list of numeric values within CSV data
    i.e., |0.1,0.2,0.3,0.4| in a "|"-separated data file. This function parses
    these data as Float64 values and assigns them to a dictionary using given
    keys; the dictionary is returned.
    Inputs:
        IDs - a list of IDs corresponding to the rows of the data in DataCol; also used as dict keys
        ID2s - a list of secondary IDs for use as keys in the dict; a list of lists
        DataCol - a column of data from a .csv file

    Note: This function replaces code like this:
    for s = 1:length(asset_id) # AssetData[s,7] is a comma-separated list
        check = typeof(AssetData[s, 7])
        if check != Float64 && check != Int64 # then it's a string of numbers
            temp = split(asset_data[s, 7],",")
            values = [parse(Float64,temp[i]) for i = 1:length(temp)] # Float64 array
        else # in the case it was a Float64 or an Int64
            values = asset_data[s, 7]
        end
        key1 = asset_id[s]
        key2s = asset_inputs[key1]
        for i = 1:length(key2s)
            asset_input_stoich[key1,key2s[i]] = values[i]
        end
    end
    """
    Out = Dict()
    L = length(IDs)
    for l = 1:L
        check = typeof(DataCol[l])
        if check != Float64 && check != Int64 # then it's a string of numbers
            temp = split(DataCol[l],",") # separate by commas into temporary list
            values = [parse(Float64,temp[i]) for i = 1:length(temp)] # parse as Float64 array
        else # in the case it was already a Float64 or an Int64
            values = DataCol[l]
        end
        key1 = IDs[l]
        key2s = ID2s[key1]
        for i = 1:length(key2s)
            Out[key1,key2s[i]] = values[i]
        end
    end
    return Out
end

function DictInit(OrderedKeyList,InitValue)
    """
    Initializes a dictionary with the keys in OrderedKeyList and assigns each
    key the value in InitValue
    Inputs:
        OrderedKeyList - a list of lists (i.e., list of lists of keys)
        InitValue - probably either 0 or false
    Outputs:
        Out - a dictionary
    Note: replaces the initialization loop for dictionaries that require full
    population; i.e., in the case of set intersections
    """
    Out = Dict()
    if length(OrderedKeyList) == 1
        for key in OrderedKeyList[1]
            Out[key] = InitValue
        end
    else
        SplatKeys = collect(Iterators.product(OrderedKeyList...))
        for key in SplatKeys
            Out[key] = InitValue
        end
    end
    return Out
end

function PrettyPrint(Data, OrderedIndexList, TruthTable=nothing; Header="*"^50, DataName="", VarName="")
    """
    Prints Data values indexed by OrderedIndexList based on whether or not
    the corresponding index value of TruthTable is true; Data and TruthTable
    share the same index pattern.
    Inputs:
        Data - an indexed data structure; a dictionary or JuMP variable
        OrderedIndexList - a list of the indices corresponding to Data and TruthTable
        TruthTable - a dictionary indexed on OrderedindexList which outputs Boolean values (true/false)
        Header - A string to print above any data
        DataName - A string to be printed as a header for the data
        VarName - A string to be printed before each line
    """
    # check truthtable; if not, default to true
    if TruthTable == nothing
        TruthTable = DictInit(OrderedIndexList, true)
    end
    # Start printing headers
    println(Header)
    println(DataName)
    # Check index index list length for proper index handling
    if length(OrderedIndexList) == 1
        SplatIndex = OrderedIndexList[1]
        for index in SplatIndex
            if TruthTable[index]
                println(VarName*"(\""*string(index)*"\"): "*string(Data[index]))
            end
        end
    else
        SplatIndex = collect(Iterators.product(OrderedIndexList...))
        for index in SplatIndex
            if TruthTable[index...]
                println(VarName*string(index)*": "*string(Data[index...]))
            end
        end
    end
end

function Nonzeros(Data, OrderedIndexList; Threshold=1E-9)
    """
    Given a dictionary of data indexed by the labels in OrderedIndexList
    returns a Boolean dictionary pointing to nonzero indices in Data, where
    nonzero is subject to a threshold value Threshold, defaulting to 1E-9.
    """
    OutDict = Dict()
    if length(OrderedIndexList) == 1
        SplatIndex = OrderedIndexList[1]
        for index in SplatIndex
            if abs(Data[index]) > Threshold
                OutDict[index] = true
            else
                OutDict[index] = false
            end
        end
    else
        SplatIndex = collect(Iterators.product(OrderedIndexList...))
        for index in SplatIndex
            if abs(Data[[i for i in index]...]) > Threshold
                OutDict[[i for i in index]...] = true
            else
                OutDict[[i for i in index]...] = false
            end
        end
    end
    return(OutDict)
end

function FilePrint(Variable,OrderedIndexList,filename;Header="*"^50,DataName="",VarName="")
    """
    Generates a list of strings and prints them to file with nice formatting;
    reduces required script code clutter.
    > Variable: the result of a JuMP getvalue() call; a Dict().
    > OrderedIndexList: a list of indices in the same order as the indices of
      the data in Variale; each element is a list of index elements. As an
      example: [A,B,C] where A = [a1,a2,...,aN], B = ....
    > filename: the file name for printing
    > Header: a string to be used as a header above the printed data
    > DataName: a header to appear above the printed data
    > VarName: the desired output name of the variable on screen; a string
    """
    # Header and DataName:
    print(filename,"\n"*Header*"\n"*DataName)

    # Collect indices via splatting to create all permutations; print each permuted index and value to file
    if length(OrderedIndexList) == 1
        SplatIndex = OrderedIndexList[1]
        for index in SplatIndex
            print(filename,"\n"*VarName*"(\""*string(index)*"\") = "*string(Variable[index]))
        end
    else
        SplatIndex = collect(Iterators.product(OrderedIndexList...))
        for index in SplatIndex
            print(filename,"\n"*VarName*string(index)*" = "*string(Variable[[i for i in index]...]))
        end
    end
end

function RawDataPrint(data,filename;Header="*"^50,DataName="")
    """
    Prints raw data to file for record-keeping purposes;
    reduces required script code clutter.
    > data: an array of data read from a .csv file.
    > filename: the file name for printing
    > Header: a string to be used as a header above the printed data
    > DataName: a header to appear above the printed data
    """
    # Header and DataName:
    print(filename,"\n"*Header*"\n"*DataName)

    # number of rows
    n = size(data)[1]

    # print rows of data array to file
    for i = 1:n
        print(filename,"\n")
        print(filename,data[i,:])
    end
end

################################################################################
### DATA IMPORT ###
node_data = readdlm(DataFolder*"/node_data.csv",'|',Any,comments=true)
arc_data = readdlm(DataFolder*"/arc_data.csv",'|',Any,comments=true)
product_data = readdlm(DataFolder*"/product_data.csv",'|',Any,comments=true)
demand_data = readdlm(DataFolder*"/demand_data.csv",'|',Any,comments=true)
supply_data = readdlm(DataFolder*"/supply_data.csv",'|',Any,comments=true)
tech_data = readdlm(DataFolder*"/technology_data.csv",'|',Any,comments=true)
techsite_data = readdlm(DataFolder*"/techsite_data.csv",'|',Any,comments=true)

################################################################################
### DATA SETUP ###
# Node data parsing
node_id = node_data[:, 1]
[node_id[i] = string(node_id[i]) for i = 1:length(node_id)]
node_alias = Dict(zip(node_id, node_data[:, 2])) # node name
node_lon = Dict(zip(node_id, node_data[:, 3])) # longitude
node_lat  = Dict(zip(node_id, node_data[:, 4])) # latitude

# Arc data parsing
arc_id = arc_data[:, 1]
[arc_id[a] = string(arc_id[a]) for a = 1:length(arc_id)] # convert to string from substring
arc_j = Dict(zip(arc_id, arc_data[:, 2])) # first node "j"
arc_k  = Dict(zip(arc_id, arc_data[:, 3])) # second node "k"
arc_cap  = Dict(zip(arc_id, arc_data[:, 4])) # arc capacity
if CustomLengths # Only need to define this data if working with customized arc lengths
    arc_len  = Dict(zip(arc_id, arc_data[:, 5])) # arc length; optional for distances
end

# Product data parsing
product_id = product_data[:, 1]
[product_id[i] = String(product_id[i]) for i = 1:length(product_id)]
product_alias = Dict(zip(product_id, product_data[:, 2])) # product name
product_trspt = Dict(zip(product_id, product_data[:, 3])) # product transport cost

# Demand data parsing
dem_id = demand_data[:, 1]
[dem_id[i] = string(dem_id[i]) for i = 1:length(dem_id)]
dem_node  = Dict(zip(dem_id, demand_data[:, 2])); # demand node
dem_prod  = Dict(zip(dem_id, demand_data[:, 3])); # demand product
dem_bid   = Dict(zip(dem_id, demand_data[:, 4])); # demand bid
dem_cap   = Dict(zip(dem_id, demand_data[:, 5])); # demand capacity

# Supply data parsing
sup_id = supply_data[:, 1]
[sup_id[i] = string(sup_id[i]) for i = 1:length(sup_id)]
sup_node  = Dict(zip(sup_id, supply_data[:, 2])); # demand node
sup_prod  = Dict(zip(sup_id, supply_data[:, 3])); # demand product
sup_bid   = Dict(zip(sup_id, supply_data[:, 4])); # demand bid
sup_cap   = Dict(zip(sup_id, supply_data[:, 5])); # demand capacity

# Technology transformation parsing
tech_id = tech_data[:, 1]
[tech_id[i] = string(tech_id[i]) for i = 1:length(tech_id)] # de-substring-ification
tech_output = TextListFromCSV(tech_id, tech_data[:,2]) # products made
tech_input = TextListFromCSV(tech_id, tech_data[:, 3]) # product consumed
tech_output_stoich = NumericListFromCSV(tech_id, tech_output, tech_data[:, 4]) # product yield factor
tech_input_stoich = NumericListFromCSV(tech_id, tech_input, tech_data[:, 5]) # reference yield factor
tech_bid_ref = Dict(zip(tech_id, tech_data[:, 6])) # reference product for bids
[tech_bid_ref[i] = string(tech_bid_ref[i]) for i in keys(tech_bid_ref)] # de-substring-ification
tech_bid = Dict(zip(tech_id, tech_data[:, 7])) # bid value; interpreted as operating cost
#tech_cap = NumericListFromCSV(tech_id, tech_input, tech_data[:, 8]) # capacity value
tech_cap = Dict(zip(tech_id, tech_data[:, 8])) # capacity value
tech_defn = Dict(zip(tech_id, tech_data[:, 9])) # technology description

# Technology site data
techsite_id = techsite_data[:, 1]
[techsite_id[i] = String(techsite_id[i]) for i = 1:length(techsite_id)]
techsite_node = Dict(zip(techsite_id, techsite_data[:, 2])) # technology node
techsite_tech = Dict(zip(techsite_id, techsite_data[:, 3])) # technology existing at specified site

################################################################################
### SET INDICES AND ALIASES ###
# Set indices
A = arc_id
N = node_id
P = product_id
Q = product_id
D = dem_id
G = sup_id
M = tech_id
L = techsite_id

# Set cardinalities (lengths)
cardA = length(A)
cardN = length(N)
cardP = length(P)
cardD = length(D)
cardG = length(G)
cardM = length(M)
cardL = length(L)

# Create an internal set of arcs to ensure that both forward and backward arcs exist
# Note: this way, user only needs to define the forward arc
for a = 1:cardA
    ai = a + cardA # shift index for new arc
    push!(A, "AI"*lpad(a,ndigits(cardA),"0")) # add a label; repeat original numbers, but prefix differently
    arc_n[A[ai]] = arc_m[A[a]] # flip arc at new position
    arc_m[A[ai]] = arc_n[A[a]] # flip arc at new position
    arc_cap[A[ai]] = arc_cap[A[a]] # same capacity
    if CustomLengths
        arc_len[A[ai]] = arc_len[A[a]] # same length
    end
end
cardA = length(A) # update cardA value

# Truth table for available arcs; nodes N and M are connected by A
AnM = Dict() # given node n, provides all nodes m in N connected by an arc a in A
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

LTJ = []
for l in L
    push!(LTJ,(techsite_tech[l],techsite_node[l]))
end

# Mapping set: product P can be used to produce product Q
TPQ = []
for t in tech_id
    for p in tech_output[t]
        for q in tech_input[t]
            push!(TPQ,(t,p,q)) # (prod,ref) pairs
        end
    end
end
TPQ = unique(TPQ) # remove duplicates

# Mapping set: node j produces product p from technology t (truth table and index list)
JPT = DictInit([J,P,T],false)
JPTlist = []
# Mapping set: node j consumes product q for technology t (truth table and index list)
JQT = DictInit([J,Q,T],false)
JQTlist = []
for ts in techsite_id
    j = techsite_node[ts] # element
    t = techsite_tech[ts] # element
    peas = tech_output[t] # list of elements
    ques = tech_input[t] # list of elements
    for p in peas
        JPT[j,p,t] = true
        push!(JPTlist,(j,p,t))
    end
    for q in ques
        JQT[j,q,t] = true
        push!(JQTlist,(j,q,t))
    end
end

# given j,p, provide the associated t's
JPt = Dict()
for j in node_id
    for p in product_id
        teas = [] # empty list of t indices
        for t in tech_id
            if JPT[j,p,t] # is true
                push!(teas,t)
            end
        end
        JPt[j,p] = teas
    end
end
# given j,q, provide the associated t's
JQt = Dict()
for j in node_id
    for q in product_id
        teas = [] # empty list of t indices
        for t in tech_id
            if JQT[j,q,t] # is true
                push!(teas,t)
            end
        end
        JQt[j,q] = teas
    end
end

################################################################################
### CALCULATED PARAMETERS ###
# Inter-node distances
node_dist = Dict()
z = 0
for j in node_id
    for k in node_id
        node_dist[j,k] = GreatCircle(node_lon[j], node_lat[j], node_lon[k], node_lat[k])
    end
end

# Maximum demand by node and product
dMAX = DictInit([J,P],0)
for j in node_id
    for p in product_id
        for d in dem_id
            if dem_node[d] == j && dem_prod[d] == p
                dMAX[j,p] += dem_cap[d]
            end
        end
    end
end

# Maximum supply by node and product
sMAX = DictInit([J,P],0)
for j in node_id
    for p in product_id
        for s in sup_id
            if sup_node[s] == j && sup_prod[s] == p
                sMAX[j,p] += sup_cap[s]
            end
        end
    end
end

α = Dict() # yield of p from q in technology t
for t in tech_id
    for p in tech_output[t] # list of products made by t
        for q in tech_input[t] # list of products consumed by t
            α[t,p,q] = tech_output_stoich[t,p]/tech_input_stoich[t,q]
        end
    end
end

# Maximum production levels
gMAX = DictInit([T,J,P],0)
for ts in techsite_id # techsite produces (t,n) pairs
    for p in tech_output[techsite_tech[ts]] # list of output products from t
        gMAX[techsite_tech[ts],techsite_node[ts],p] = tech_output_stoich[techsite_tech[ts],p]*tech_cap[techsite_tech[ts]]
    end
end

xMAX = DictInit([T,J,Q],0)
for ts in techsite_id # produces (t,n) pairs
    for q in tech_input[techsite_tech[ts]] # a list of product id's
        xMAX[techsite_tech[ts],techsite_node[ts],q] = tech_input_stoich[techsite_tech[ts],q]*tech_cap[techsite_tech[ts]] # capacity for technology at ts
    end
end

# Require specialized set of big M constraints for flow variable f
# All j=k scenarios should be zero
fMAX = DictInit([J,K,P],0)
for a in arc_id
    j = arc_j[a]
    k = arc_k[a]
    if AJK[j,k]
        for p in product_id
            #fMAX[j,k,p] = minimum([sMAX[j,p] + sum(gMAX[t,j,p] for t in tech_id), arc_cap[a]])
            fMAX[j,k,p] = arc_cap[a]
            fMAX[k,j,p] = fMAX[j,k,p]
        end
    end
end

################################################################################
### MODEL STATEMENT ###
MOD = JuMP.Model(optimizer_with_attributes(Gurobi.Optimizer,"OutputFlag"=>0))
#M = JuMP.Model(with_optimizer(Ipopt.Optimizer))

################################################################################
### VARIABLES ###
# Model variables
@variable(MOD, 0 <= s[j=J,p=P] <= sMAX[j,p]) # total supply by product and node
@variable(MOD, 0 <= d[j=J,p=P] <= dMAX[j,p]) # total demand by product and node
@variable(MOD, 0 <= sl[ss=S] <= sup_cap[ss]) # individual supplies by supply list
@variable(MOD, 0 <= dl[dd=D] <= dem_cap[dd]) # individual demands by demand list
@variable(MOD, 0 <= f[j=J,k=K,p=P] <= fMAX[j,k,p]) # transport from j to k
@variable(MOD, 0 <= x[t=T,j=J,q=Q] <= xMAX[t,j,q]) # consumption, standard: P committed for production of something else
@variable(MOD, 0 <= g[t=T,j=J,p=P] <= gMAX[t,j,p]) # generation, standard:  P produced from something else

################################################################################
### EQUATIONS ###
# supply and demand total equal total of individual supplies and individual demands
@constraint(MOD, SupplyBalance[j=J,p=P], s[j,p] == sum(sl[ss] for ss in S if sup_node[ss] == j && sup_prod[ss] == p))
@constraint(MOD, DemandBalance[j=J,p=P], d[j,p] == sum(dl[dd] for dd in D if dem_node[dd] == j && dem_prod[dd] == p))

# System mass balance
@constraint(MOD, Balance[j=J,p=P], s[j,p] + sum(f[k,j,p] for k in K if AJK[k,j]) + sum(g[t,j,p] for t in JPt[j,p])
    == d[j,p] + sum(f[j,k,p] for k in K if AJK[j,k]) + sum(x[t,j,p] for t in JQt[j,p]))

# Conversion relationships (yield-based)
@constraint(MOD, Conversion[j=J,(t,p,q) in TPQ], g[t,j,p] == α[t,p,q]*x[t,j,q])

################################################################################
### OBJECTIVE ###
# Revenue equations
demand_revenue = @expression(MOD, sum(dem_bid[dd]*dl[dd] for dd in D))
supply_revenue = @expression(MOD, sum(sup_bid[ss]*sl[ss] for ss in S))
transport_revenue = @expression(MOD, sum(product_trspt[p]*node_dist[j,k]*f[j,k,p] for j in J,k in K,p in P))
operating_revenue = @expression(MOD, sum(x[t,j,q]*tech_bid[t] for t in T, j in J, q in Q if (JQT[j,q,t] && tech_bid_ref[t] == q)))

# Full objective
@objective(MOD, Max, demand_revenue - supply_revenue - transport_revenue - operating_revenue)

################################################################################
### DISPLAY MODEL FORMULATION ###
filename = open(DataFolder*"/"*ModelOutputFileName,"w")
print(filename, MOD)
close(filename)
if PrintModel == true
    print(MOD)
end

################################################################################
### SOLVE AND DATA RETRIEVAL ###
# Display statistics
println(PrintSpacer*"\nModel statistics:")
println("Variables: "*string(length(all_variables(MOD))))
println("Total inequality constraints: "*string(num_constraints(MOD,AffExpr, MOI.LessThan{Float64})+num_constraints(MOD,AffExpr, MOI.GreaterThan{Float64})+num_constraints(MOD,VariableRef, MOI.LessThan{Float64})+num_constraints(MOD,VariableRef, MOI.GreaterThan{Float64})))
println("Total equality constraints: "*string(num_constraints(MOD,VariableRef, MOI.EqualTo{Float64})+num_constraints(MOD,AffExpr, MOI.EqualTo{Float64})))
println("Variable bounds: "*string(num_constraints(MOD,VariableRef, MOI.LessThan{Float64})+num_constraints(MOD,VariableRef, MOI.GreaterThan{Float64})))
println("Model inequality constraints: "*string(num_constraints(MOD,AffExpr, MOI.LessThan{Float64})+num_constraints(MOD,AffExpr, MOI.GreaterThan{Float64})))
println("Model equality constraints: "*string(num_constraints(MOD,AffExpr, MOI.EqualTo{Float64})))
println(PrintSpacer)

# Solve
println("Solving original problem...")
JuMP.optimize!(MOD)
println("Primal status: "*string(primal_status(MOD)))
println("Dual status: "*string(dual_status(MOD)))
z_out = JuMP.objective_value(MOD)
s_out = JuMP.value.(s)
d_out = JuMP.value.(d)
sl_out = JuMP.value.(sl)
dl_out = JuMP.value.(dl)
f_out = JuMP.value.(f)
x_out = JuMP.value.(x)
g_out = JuMP.value.(g)
cp_out = JuMP.dual.(Balance)

################################################################################
### PROFIT CALCULATIONS ###

PhiSupply = Dict()
for ss in S
    PhiSupply[ss] = (cp_out[sup_node[ss],sup_prod[ss]] - sup_bid[ss])*sl_out[ss]
end

PhiDemand = Dict()
for dd in D
    PhiDemand[dd] = (dem_bid[dd] - cp_out[dem_node[dd],dem_prod[dd]])*dl_out[dd]
end

PhiTransport = Dict()
cp_transport = Dict()
for j in J
    for k in K
        for p in P
            # transport prices (notation: j -> k for p)
            cp_transport[j,k,p] = cp_out[k,p] - cp_out[j,p]
            # transport profits
            PhiTransport[j,k,p] = (cp_transport[j,k,p] - product_trspt[p])*f_out[j,k,p]
        end
    end
end

PhiTech = DictInit([T,J],0)
cp_tech = Dict()
for t in T
    for j in J
        # technology prices
        cp_tech[t,j] = sum(cp_out[j,p]*tech_output_stoich[t,p] for p in tech_output[t]) - sum(cp_out[j,q]*tech_input_stoich[t,q] for q in tech_input[t])
    end
end
for ts in techsite_id
    j = techsite_node[ts]
    t = techsite_tech[ts]
    p = tech_bid_ref[t]
    PhiTech[t,j] = (cp_tech[t,j] - tech_input_stoich[t,p]*tech_bid[t])*x_out[t,j,tech_bid_ref[t]]
end

################################################################################
### WRITE OUTPUT TO FILE AND DISPLAY TO REPL ###
filename = open(DataFolder*"/"*SolutionOutputFileName,"w")
print(filename, PrintSpacer*"\nModel statistics:")
print(filename, "\nVariables: "*string(length(all_variables(MOD))))
print(filename, "\nTotal inequality constraints: "*string(num_constraints(MOD,AffExpr, MOI.LessThan{Float64})+num_constraints(MOD,AffExpr, MOI.GreaterThan{Float64})+num_constraints(MOD,VariableRef, MOI.LessThan{Float64})+num_constraints(MOD,VariableRef, MOI.GreaterThan{Float64})))
print(filename, "\nTotal equality constraints: "*string(num_constraints(MOD,VariableRef, MOI.EqualTo{Float64})+num_constraints(MOD,AffExpr, MOI.EqualTo{Float64})))
print(filename, "\nVariable bounds: "*string(num_constraints(MOD,VariableRef, MOI.LessThan{Float64})+num_constraints(MOD,VariableRef, MOI.GreaterThan{Float64})))
print(filename, "\nModel inequality constraints: "*string(num_constraints(MOD,AffExpr, MOI.LessThan{Float64})+num_constraints(MOD,AffExpr, MOI.GreaterThan{Float64})))
print(filename, "\nModel equality constraints: "*string(num_constraints(MOD,AffExpr, MOI.EqualTo{Float64})))
print(filename, "\n"*PrintSpacer*"\nObjective value: "*string(z_out))
FilePrint(s_out,[J,P],filename,DataName="Supply values:",VarName="s")
FilePrint(d_out,[J,P],filename,DataName="Demand values:",VarName="d")
FilePrint(f_out,[J,K,P],filename,DataName="Transport values:",VarName="f")
FilePrint(x_out,[T,J,P],filename,DataName="Consumption values:",VarName="x")
FilePrint(g_out,[T,J,P],filename,DataName="Generation values:",VarName="g")
FilePrint(cp_out,[J,P],filename,DataName="Nodal clearing prices:",VarName="π")
FilePrint(cp_transport,[J,K,P],filename,DataName="Transport clearing prices:",VarName="π_f")
FilePrint(cp_tech,[T,J],filename,DataName="Technology clearing prices:",VarName="π_t")
FilePrint(PhiDemand,[D],filename,DataName="Demand profits:",VarName="Φ_D")
FilePrint(PhiSupply,[S],filename,DataName="Supply profits:",VarName="Φ_S")
FilePrint(PhiTransport,[J,K,P],filename,DataName="Transport profits:",VarName="Φ_f")
FilePrint(PhiTech,[T,J],filename,DataName="Technology profits:",VarName="Φ_t")
# To add source data to files:
print(filename, "\n"*PrintSpacer*"\nRaw data:")
RawDataPrint(node_data,filename,DataName="Node data:")
RawDataPrint(arc_data,filename,DataName="Arc data:")
RawDataPrint(product_data,filename,DataName="Product data:")
RawDataPrint(demand_data,filename,DataName="Demand data:")
RawDataPrint(supply_data,filename,DataName="Supply data:")
RawDataPrint(tech_data,filename,DataName="Technology data:")
RawDataPrint(techsite_data,filename,DataName="Technology site data:")
close(filename)

# And print to REPL
if PrintOutput
    println(PrintSpacer)
    println("Objective value: ", z_out)
    # NOTE to display all values, replace Nonzeros() with DictInit([A,B,...Z],true)
    PrettyPrint(s_out, [J,P], Nonzeros(s_out, [J,P]), DataName="Supply values:", VarName="s")
    PrettyPrint(d_out, [J,P], Nonzeros(d_out, [J,P]), DataName = "Demand values:", VarName="d")
    PrettyPrint(f_out, [J,K,P], Nonzeros(f_out, [J,K,P]), DataName = "Transport values:", VarName="f")
    #PrettyPrint(f_out, [J,K,P], JKPTruthTable, DataName = "Transport values:", VarName="f")
    PrettyPrint(x_out, [T,J,P], Nonzeros(x_out, [T,J,P]), DataName = "Consumption values:", VarName="x")
    PrettyPrint(g_out, [T,J,P], Nonzeros(g_out, [T,J,P]), DataName = "Generation values:", VarName="g")
    PrettyPrint(cp_out, [J,P], Nonzeros(cp_out, [J,P]), DataName = "Nodal clearing prices:", VarName="π")
    PrettyPrint(cp_transport, [J,K,P], Nonzeros(cp_transport, [J,K,P]), DataName = "Transport clearing prices:", VarName="π_f")
    #PrettyPrint(cp_transport, [J,K,P], JKPTruthTable, DataName = "Transport clearing prices:", VarName="π_f")
    PrettyPrint(cp_tech, [T,J], Nonzeros(cp_tech, [T,J]), DataName = "Technology clearing prices:", VarName="π_t")
    PrettyPrint(PhiDemand, [D], Nonzeros(PhiDemand, [D]), DataName = "Demand profits:", VarName="Φ_D")
    PrettyPrint(PhiSupply, [S], Nonzeros(PhiSupply, [S]), DataName = "Supply profits:", VarName="Φ_S")
    PrettyPrint(PhiTransport, [J,K,P], Nonzeros(PhiTransport, [J,K,P]), DataName = "Transport profits:", VarName="Φ_f")
    PrettyPrint(PhiTech, [T,J], Nonzeros(PhiTech, [T,J]), DataName = "Technology profits:", VarName="Φ_t")
    println(PrintSpacer)
end

################################################################################
### END OF CODE ###
println(PrintSpacer,"\nAll done\n",PrintSpacer)
