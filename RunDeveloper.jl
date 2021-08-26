################################################################################
### ADD AS DEVELOPMENT PACKAGE
#Pkg.dev "/Users/ptominac/Documents/Code/CoordinatedSupplyChains"
# include("RunDeveloper.jl")

################################################################################
### USING STATEMENT
using CoordinatedSupplyChains

A,N,P,D,S,T,L,Sets,Pars = LoadSSCaseData("/Users/ptominac/Documents/Code/CoordinatedSupplyChains/TestCases/TestV36");

Output = OptimizeSSCase(A,N,P,D,S,T,L,Sets,Pars,CaseDataDirectory="/Users/ptominac/Documents/Code/CoordinatedSupplyChains/TestCases/TestV36");

SSRecordMaker(A,N,P,D,S,T,L,Output, CaseDataDirectory="/Users/ptominac/Documents/Code/CoordinatedSupplyChains/TestCases/TestV36")

NetworkPlot(A,N,P,D,S,L,Output.f,CaseDataDirectory="/Users/ptominac/Documents/Code/CoordinatedSupplyChains/TestCases/TestV36")

println("Script Done")