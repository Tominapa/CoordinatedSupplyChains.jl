################################################################################
### CUSTOM DATA STRUCTURES
#=
Custom data structures are defined here 
(structures are immutable by default; if modification is required, use "mutable struct") 
=#

################################################################################
### PRIMARY INDEX SETS
struct ArcDataStruct
    ID::Array
    node_s::Dict
    node_r::Dict
    cap::Dict
    len::Dict
end

struct NodeDataStruct
    ID::Array
    alias::Dict
    lon::Dict
    lat::Dict
end

struct ProductDataStruct
    ID::Array
    alias::Dict
    transport_cost::Dict
end

struct DemandDataStruct
    ID::Array
    node::Dict
    prod::Dict
    bid::Dict
    cap::Dict
end

struct SupplyDataStruct
    ID::Array
    node::Dict
    prod::Dict
    bid::Dict
    cap::Dict
end

struct TechDataStruct
    ID::Array
    Outputs::Dict
    Inputs::Dict
    OutputYields::Dict
    InputYields::Dict
    InputRef::Dict
    bid::Dict
    cap::Dict
    alias::Dict
end

struct TechsiteDataStruct
    ID::Array
    node::Dict
    tech::Dict
end

################################################################################
### SECONDARY SETS (SUBSETS, OR INTERSECTIONS OF TWO OR MORE PRIMARY INDICES)
struct SetStruct
    Ain::Dict
    Aout::Dict
    TPQ::Array
    NQT::Dict
    NPt::Dict
    NQt::Dict
end

################################################################################
### PARAMETERS
struct ParStruct
    dMAX::Dict
    sMAX::Dict
    α::Dict
    ξgenMAX::Dict
    ξconMAX::Dict
    fMAX::Dict
end

################################################################################
### MODEL OUTPUTS
struct OutputStruct
    z::Float64
    si::JuMP.Containers.DenseAxisArray
    dj::JuMP.Containers.DenseAxisArray
    snp::JuMP.Containers.DenseAxisArray
    dnp::JuMP.Containers.DenseAxisArray
    f::JuMP.Containers.DenseAxisArray
    ξcon::JuMP.Containers.DenseAxisArray
    ξgen::JuMP.Containers.DenseAxisArray
    πNP::JuMP.Containers.DenseAxisArray
    πA::Dict
    πT::Dict
    Φd::Dict
    Φs::Dict
    Φf::Dict
    Φξ::Dict
end

struct StatStruct
    NumVars::Float64
    TotalIneqCons::Float64
    TotalEqCons::Float64
    NumVarBounds::Float64
    ModelIneqCons::Float64
    ModelEqCons::Float64
end