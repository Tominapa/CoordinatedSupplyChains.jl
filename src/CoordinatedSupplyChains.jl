module CoordinatedSupplyChains

################################################################################
### IMPORT LIST
using DelimitedFiles
using JuMP
using HiGHS

################################################################################
### EXPORT LIST
#= List all usable functions here; this makes them callable to users =#
export RunCSC, BuildModelData, BuildModel, GetModelStats, SolveModel, PostSolveCalcs, SaveSolution

################################################################################
### INCLUDE STATEMENTS FOR CODE IN SEPARATE FILES

# Supporting functions
#= Useful functions that support model building; e.g., distance calculations,
dictionary initialization, etc.; not for export =#
include("SupportFunctions.jl")

# Data structure definitions
#= These describe the primary data structures that the model will use; nothing to export =#
include("StructureDefns.jl")

#= These functions help build the data structures for the model; EXPORT =#
include("BuilderFunctions.jl")

# Data import functions
#= Functions that import individual model case studies and build the data structures
for a market model; EXPORT =#
include("DataSetup.jl")

# Model building functions; EXPORT
include("ModelSetup.jl")

# Workflow functions to simplify use; EXPORT
include("WorkflowFunctions.jl")

################################################################################
### CONSTANT VALUES
const PrintSpacer = "*"^50
const DefaultOptimizer = HiGHS.Optimizer
end

#Test lines; delete once testing documentation is done.
#RunCSC("/Users/ptominac/Documents/environmentaleconomics/BilevelImpactMarkets/Code/ExtendedTestSets/NoArcs", optimizer=Gurobi.Optimizer)