module CoordinatedSupplyChains

################################################################################
### IMPORT LIST
using DelimitedFiles
using JuMP
using Clp
using Plots
#using PGFPlotsX
pgfplotsx()

################################################################################
### EXPORT LIST
#= List all usable functions here; this makes them callable to users =#
export LoadSSCaseData, OptimizeSSCase, SSRecordMaker, SSNetworkPlot, RunSSCase

################################################################################
### INCLUDE STATEMENTS FOR CODE IN SEPARATE FILES

# Structure definitions used by functions - no functions contained; nothing to export
include("StructureDefinitions.jl")

# Support functions required by other code; not to be callable by users - DO NOT EXPORT
include("SupportFunctions.jl")

# Functions for importing standardized model data - EXPORT
include("ImportFunctions.jl")

# Functions for solving coordinated supply chain models with JuMP - EXPORT
include("OptimizationFunctions.jl")

# Functions for exporting model results - EXPORT
include("OutputFunctions.jl")

# Functions for plotting results - EXPORT
include("PlottingFunctions.jl")

# Functions for running full workflows - EXPORT
include("WorkflowFunctions.jl")
end
