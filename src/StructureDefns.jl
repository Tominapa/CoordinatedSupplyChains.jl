################################################################################
### DEFINE DATA STRUCTURES "STRUCT" FOR USE IN MAIN MODEL

################################################################################
### PRIMARY INDEX SETS
struct TimeDataStruct
    ID::Vector{String}
    dt::Dict{String,Float64}
end

struct NodeDataStruct
    ID::Vector{String}
    alias::Dict{String,String}
    lon::Dict{String,Float64}
    lat::Dict{String,Float64}
end

struct ArcDataStruct
    ID::Vector{String}
    n_send::Dict{String,String}
    n_recv::Dict{String,String}
    t_send::Dict{String,String}
    t_recv::Dict{String,String}
    bid::Dict{Tuple{String,String},Float64}
    cap::Dict{Tuple{String,String},Float64}
    len::Dict{String,Float64}
    dur::Dict{String,Float64}
    ID_S::Vector{String}
    ID_T::Vector{String}
    ID_ST::Vector{String}
end

struct ProductDataStruct
    ID::Vector{String}
    alias::Dict{String,String}
    transport_cost::Dict{String,Float64}
    storage_cost::Dict{String,Float64}
end

struct ImpactDataStruct
    ID::Vector{String}
    alias::Dict{String,String}
    transport_coeff::Dict{String,Float64}
    storage_coeff::Dict{String,Float64}
end

struct DemandDataStruct
    ID::Vector{String}
    node::Dict{String,String}
    time::Dict{String,String}
    prod::Dict{String,String}
    bid::Dict{String,Float64}
    cap::Dict{String,Float64}
    Impacts::Dict{String,Vector{String}}
    ImpactYields::Dict{Tuple{String,String},Float64}
end

struct SupplyDataStruct
    ID::Vector{String}
    node::Dict{String,String}
    time::Dict{String,String}
    prod::Dict{String,String}
    bid::Dict{String,Float64}
    cap::Dict{String,Float64}
    Impacts::Dict{String,Vector{String}}
    ImpactYields::Dict{Tuple{String,String},Float64}
end

struct EnvDataStruct
    ID::Vector{String}
    node::Dict{String,String}
    time::Dict{String,String}
    impact::Dict{String,String}
    bid::Dict{String,Float64}
    cap::Dict{String,Float64}
end

struct TechDataStruct
    ID::Vector{String}
    Outputs::Dict{String,Vector{String}}
    Inputs::Dict{String,Vector{String}}
    Impacts::Dict{String,Vector{String}}
    OutputYields::Dict{Tuple{String,String},Float64}
    InputYields::Dict{Tuple{String,String},Float64}
    ImpactYields::Dict{Tuple{String,String},Float64}
    InputRef::Dict{String,String}
    bid::Dict{String,Float64}
    cap::Dict{String,Float64}
    alias::Dict{String,String}
end

struct TechmapDataStruct
    ID::Vector{String}
    node::Dict{String,String}
    time::Dict{String,String}
    tech::Dict{String,String}
end

struct SetStruct
    T1::Vector{String}
    Tt::Vector{String}
    TT::Vector{String}
    Tprior::Dict{String,String}
    Tpost::Dict{String,String}
    Ain::Union{Dict{Tuple{String,String},Vector{String}}, Nothing}
    Aout::Union{Dict{Tuple{String,String},Vector{String}}, Nothing}
    Dntp::Dict{Tuple{String,String,String},Vector{String}}
    Gntp::Dict{Tuple{String,String,String},Vector{String}}
    Dntq::Union{Dict{Tuple{String,String,String},Vector{String}}, Nothing}
    Gntq::Union{Dict{Tuple{String,String,String},Vector{String}}, Nothing}
    Vntq::Union{Dict{Tuple{String,String,String},Vector{String}}, Nothing}
    DQ::Union{Vector{String}, Nothing}
    GQ::Union{Vector{String}, Nothing}
    NTPgenl::Union{Dict{Tuple{String,String,String},Vector{String}}, Nothing}
    NTPconl::Union{Dict{Tuple{String,String,String},Vector{String}}, Nothing}
    NTQgenl::Union{Dict{Tuple{String,String,String},Vector{String}}, Nothing}
end

struct ParStruct
    gMAX::Dict{Tuple{String,String,String},Float64} # maximum nodal supply
    dMAX::Dict{Tuple{String,String,String},Float64} # maximum nodal demand
    eMAX::Union{Dict{Tuple{String,String,String},Float64}, Nothing} # maximum environmental demand
    γiq::Union{Dict{Tuple{String,String},Float64}, Nothing} # supply impact yield
    γjq::Union{Dict{Tuple{String,String},Float64}, Nothing} # demand impact yield
    γaq::Union{Dict{Tuple{String,String},Float64}, Nothing} # transport impact yield
    γmp::Union{Dict{Tuple{String,String},Float64}, Nothing} # technology product yield
    γmq::Union{Dict{Tuple{String,String},Float64}, Nothing} # technology impact yield
    ξgenMAX::Union{Dict{Tuple{String,String},Float64}, Nothing} # technology generation capacity
    ξconMAX::Union{Dict{Tuple{String,String},Float64}, Nothing} # technology consumption capacity
    ξenvMAX::Union{Dict{Tuple{String,String},Float64}, Nothing} # technology impact capacity
end

struct ModelStatStruct
    Variables::Int
    TotalInequalityConstraints::Int
    TotalEqualityConstraints::Int
    VariableBounds::Int
    ModelInequalityConstrtaints::Int
    ModelEqualityConstraints::Int
end

struct SolutionStruct
    TermStat::String
    PrimalStat::String
    DualStat::String
    z::Float64
    g::JuMP.Containers.DenseAxisArray
    d::JuMP.Containers.DenseAxisArray
    e::Union{JuMP.Containers.DenseAxisArray,Nothing}
    f::Union{JuMP.Containers.DenseAxisArray,Nothing}
    ξ::Union{JuMP.Containers.DenseAxisArray,Nothing}
    πp::JuMP.Containers.DenseAxisArray
    πq::Union{JuMP.Containers.DenseAxisArray,Nothing}
end

struct PostSolveValues
    gNTP::Dict{Tuple{String,String,String},Float64}
    dNTP::Dict{Tuple{String,String,String},Float64}
    eNTQ::Union{Dict{Tuple{String,String,String},Float64},Nothing}
    ξgen::Union{Dict{Tuple{String,String},Float64},Nothing}
    ξcon::Union{Dict{Tuple{String,String},Float64},Nothing}
    ξenv::Union{Dict{Tuple{String,String},Float64},Nothing}
    π_iq::Union{Dict{Tuple{String,String},Float64},Nothing}
    π_jq::Union{Dict{Tuple{String,String},Float64},Nothing}
    π_a::Union{Dict{Tuple{String,String},Float64},Nothing}
    π_aq::Union{Dict{Tuple{String,String},Float64},Nothing}
    π_m::Union{Dict{Tuple{String,String,String},Float64},Nothing}
    π_mq::Union{Dict{Tuple{String,String,String,String},Float64},Nothing}
    ϕi::Dict{String,Float64}
    ϕj::Dict{String,Float64}
    ϕv::Union{Dict{String,Float64},Nothing}
    ϕl::Union{Dict{String,Float64},Nothing}
    ϕa::Union{Dict{Tuple{String,String},Float64},Nothing}
end

# Control flow based on input data
struct DataCF
    UseTime::Bool # are time points provided?
    UseArcs::Bool # are arcs provided?
    UseTechs::Bool # are technologies provided?
    UseImpacts::Bool # are impact data provided?
end