################################################################################
### DEFINE DATA STRUCTURES "STRUCT" FOR USE IN MAIN MODEL

################################################################################
### PRIMARY INDEX SETS
struct TimeDataStruct
    ID::Array
    dt::Dict
end

struct NodeDataStruct
    ID::Array
    alias::Dict
    lon::Dict
    lat::Dict
end

struct ArcDataStruct
    ID::Array
    n_send::Dict
    n_recv::Dict
    t_send::Dict
    t_recv::Dict
    bid::Dict
    cap::Dict
    len::Dict
    dur::Dict
    ID_S::Array
    ID_T::Array
    ID_ST::Array
end

struct ProductDataStruct
    ID::Array
    alias::Dict
    transport_cost::Dict
    storage_cost::Dict
end

struct ImpactDataStruct
    ID::Array
    alias::Dict
    transport_coeff::Dict
    storage_coeff::Dict
end

struct DemandDataStruct
    ID::Array
    node::Dict
    time::Dict
    prod::Dict
    bid::Dict
    cap::Dict
    Impacts::Dict
    ImpactYields::Dict
end

struct SupplyDataStruct
    ID::Array
    node::Dict
    time::Dict
    prod::Dict
    bid::Dict
    cap::Dict
    Impacts::Dict
    ImpactYields::Dict
end

struct EnvDataStruct
    ID::Array
    node::Dict
    time::Dict
    impact::Dict
    bid::Dict
    cap::Dict
end

struct TechDataStruct
    ID::Array
    Outputs::Dict
    Inputs::Dict
    Impacts::Dict
    OutputYields::Dict
    InputYields::Dict
    ImpactYields::Dict
    InputRef::Dict
    bid::Dict
    cap::Dict
    alias::Dict
end

struct TechmapDataStruct
    ID::Array
    node::Dict
    time::Dict
    tech::Dict
end

struct SetStruct
    T1::Array
    Tt::Array
    TT::Array
    Tprior::Dict
    Tpost::Dict
    Ain::Union{Dict, Nothing}
    Aout::Union{Dict, Nothing}
    Dntp::Dict
    Gntp::Dict
    Dntq::Union{Dict, Nothing}
    Gntq::Union{Dict, Nothing}
    Vntq::Union{Dict, Nothing}
    DQ::Union{Array, Nothing}
    GQ::Union{Array, Nothing}
    NTPgenl::Union{Dict, Nothing}
    NTPconl::Union{Dict, Nothing}
    NTQgenl::Union{Dict, Nothing}
end

struct ParStruct
    gMAX::Dict # maximum nodal supply
    dMAX::Dict # maximum nodal demand
    eMAX::Union{Dict, Nothing} # maximum environmental demand
    γiq::Union{Dict, Nothing} # supply impact yield
    γjq::Union{Dict, Nothing} # demand impact yield
    γaq::Union{Dict, Nothing} # transport impact yield
    γmp::Union{Dict, Nothing} # technology product yield
    γmq::Union{Dict, Nothing} # technology impact yield
    ξgenMAX::Union{Dict, Nothing} # technology generation capacity
    ξconMAX::Union{Dict, Nothing} # technology consumption capacity
    ξenvMAX::Union{Dict, Nothing} # technology impact capacity
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
    gNTP::Dict
    dNTP::Dict
    eNTQ::Union{Dict,Nothing}
    ξgen::Union{Dict,Nothing}
    ξcon::Union{Dict,Nothing}
    ξenv::Union{Dict,Nothing}
    π_iq::Union{Dict,Nothing}
    π_jq::Union{Dict,Nothing}
    π_a::Union{Dict,Nothing}
    π_aq::Union{Dict,Nothing}
    π_m::Union{Dict,Nothing}
    π_mq::Union{Dict,Nothing}
    ϕi::Dict
    ϕj::Dict
    ϕv::Union{Dict,Nothing}
    ϕl::Union{Dict,Nothing}
    ϕa::Union{Dict,Nothing}
end

# Control flow based on input data
struct DataCF
    UseTime::Bool # are time points provided?
    UseArcs::Bool # are arcs provided?
    UseTechs::Bool # are technologies provided?
    UseImpacts::Bool # are impact data provided?
end