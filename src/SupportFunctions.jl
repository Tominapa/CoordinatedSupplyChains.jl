################################################################################
### SUPPORTING FUNCTIONS - NOT FOR CALLING BY USER

# mean Earth radius used for Great Circle distance calculation
const R = 6335.439
function GreatCircle(ref_lon::Float64, ref_lat::Float64, dest_lon::Float64, dest_lat::Float64)
    """
    Calculates the great circle distance between a reference location (ref)
    and a destination (dest) and returns the great circle distances in km
    """
    # haversine formula for Great Circle distance calculation
    dist = 2.0*R*asin(sqrt(((sind((dest_lat - ref_lat)/2))^2) +
        cosd(dest_lat)*cosd(ref_lat)*((sind((dest_lon - ref_lon)/2))^2)))
    return dist
end
function GreatCircle(ref_lon::Vector{Float64}, ref_lat::Vector{Float64}, dest_lon::Vector{Float64}, dest_lat::Vector{Float64})
    """
    Calculates the great circle distance between a reference location (ref)
    and a destination (dest) and returns the great circle distances in km
    """
    # haversine formula for Great Circle distance calculation, vectorized
    dist = 2.0.*R.*asin.(sqrt.(((sind.((dest_lat .- ref_lat)./2)).^2) +
        cosd.(dest_lat).*cosd.(ref_lat).*((sind.((dest_lon .- ref_lon)./2)).^2)))
    return dist
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
        Out[IDs[i]] = [String(i) for i in split(DataCol[i],"|")]
    end
    return Out
end

function NumericListFromCSV(IDs,ID2s::Dict,DataCol)
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
        if DataCol[l] != "" # if blank, ignore entry
            check = typeof(DataCol[l])
            if check != Float64 && check != Int64 # then it's a string of numbers
                temp = split(DataCol[l],"|") # separate by pipes into temporary list
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
    end
    return Out
end

function NumericListFromCSV(IDs,ID2s::Array,DataCol)
    """
    If ID2s is an Array (i.e., full loop over IDs and ID2s)
    """
    Out = Dict()
    L = length(IDs)
    for l = 1:L
        check = typeof(DataCol[l])
        if check != Float64 && check != Int64 # then it's a string of numbers
            temp = split(DataCol[l],"|") # separate by commas into temporary list
            values = [parse(Float64,temp[i]) for i = 1:length(temp)] # parse as Float64 array
        else # in the case it was already a Float64 or an Int64
            values = DataCol[l]
        end
        # Assign keys and values to output dictionary
        for i = 1:length(ID2s)
            Out[IDs[l],ID2s[i]] = values[i]
        end
    end
    return Out
end

function KeyArrayInit(OrderedKeyList)
    """
    Creates an array containing all combiinations of the keys in in OrderedKeyList;
    identical to DictInit() and DictListInit() functionality, but doesn't
    create a dictionary; just the array of keys
    Inputs:
        OrderedKeyList - a list of lists (i.e., list of lists of keys)
    Outputs:
        Out - an array of keys
    """
    if length(OrderedKeyList) == 1
        return OrderedKeyList[1]
    else
        return collect(Iterators.product(OrderedKeyList...))
    end
end

function DictListInit(OrderedKeyList,InitFunction)
    """
    Initializes a dictionary with the keys in OrderedKeyList and assigns each
    key an empty array defined by InitFunction
    Inputs:
        OrderedKeyList - a list of lists (i.e., list of lists of keys)
        InitFunction - a function producing an empty array
    Outputs:
        Out - a dictionary
    """
    if length(OrderedKeyList) == 1
        return Dict(key => InitFunction() for key in OrderedKeyList[1])
    else
        return Dict(key => InitFunction() for key in collect(Iterators.product(OrderedKeyList...)))
    end
end

function InitStringArray()
    """
    Returns an empty String array; function for use with DictListInit
    """
    return Array{String}(undef,0)
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
    Notes:
        1) replaces the initialization loop for dictionaries that require full
        population; i.e., in the case of set intersections
        2) DO NOT USE WHERE InitValue IS ::Function
    """
    if length(OrderedKeyList) == 1
        return Dict(key => InitValue for key in OrderedKeyList[1])
    else
        return Dict(key => InitValue for key in collect(Iterators.product(OrderedKeyList...)))
    end
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
    if TruthTable === nothing
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

function PurgeQuotes(d::Dict)
    """
    Removes empty quote strings ("") from dictionaries
    Inputs:
        - arr, an array
    Outputs:
        - cleaned array
    """
    for k in keys(d)
        if d[k] == [""]
            d[k] = InitStringArray()
        end
    end
    return d
end

#=
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
=#

function EnvDataGen(N,T,Q,InitValues,filedir)
    """
    Generates a default list of environmental stakeholders
    based on node and time IDs, and sets a default bid (tax)
    for each impact type using InitValueas. Just a convenient
    way to create this file.
    Inputs:
        - N: node IDs
        - T: time IDs
        - Q: impact IDs
        - InitValues: bid values; same length as Q
        - filedir: file location for csvdata_env.csv
    Outputs:
        - text file: csvdata_env.csv
    """
    ### Setup
    CardN = length(N)
    CardT = length(T)
    CardQ = length(Q)
    CardV = CardN*CardT*CardQ
    Vdigits = ndigits(CardV)

    header = "# 1. Env. stakeholder reference| 2. Node| 3. Time| 4. Impact| 5. Bid (USD/impact unit)"

    # Open file
    filename = open(joinpath(filedir,"csvdata_env.csv"),"w")
        # print header line with column information
        print(filename, header)
        # build list of default environmental stakeholders
        OrdV = 0
        for n = 1:CardN
            for t = 1:CardT
                for q = 1:CardQ
                    OrdV += 1
                    print(filename, "\nV"*lpad(OrdV,Vdigits,"0")*"|"*N[n]*"|"*T[t]*"|"*Q[q]*"|"*string(InitValues[q]))
                end
            end
        end
    close(filename)

    return
end
# EnvDataGen(N.ID,T.ID,Q.ID,[0,0,0],"TestSets/BuildTest01")