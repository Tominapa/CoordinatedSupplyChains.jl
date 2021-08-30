using CoordinatedSupplyChains
using Test

@testset "CoordinatedSupplyChains.jl" begin
    # Write your tests here
    dir = joinpath(@__DIR__,"TestV01")

    A,N,P,D,S,T,L,Sets,Pars = CoordinatedSupplyChains.LoadSSCaseData(dir)
    @test A.ID[1] == "A01"

    Output, Stats = OptimizeSSCase(A,N,P,D,S,T,L,Sets,Pars; CaseDataDirectory=dir)
    @test Output.z == 1.450100720657891e6
    @test Stats.NumVars == 3490

    SSRecordMaker(A,N,P,D,S,T,L,Output,Stats; CaseDataDirectory=dir)
    @test isdir(joinpath(dir,"records"))==true
    @test isfile(joinpath(dir,"records/model_stats.txt"))==true

    SSNetworkPlot(A,N,P,D,S,L,Output.f; CaseDataDirectory=dir, TestMode=true)
    @test isdir(joinpath(dir,"plots"))==true
    #@test isfile(joinpath(dir,"plots/NetworkPlot.png"))==true

    # Delete everything added by the code once the tests are run
    rm(joinpath(dir,"_Model.txt"))
    rm(joinpath(dir,"_SolutionData.txt"))
    rm(joinpath(dir,"records"), recursive=true)
    rm(joinpath(dir,"plots"), recursive=true)

    # RunSSCase calls the four previous functions again; the optional keyword options are reversed here to improve coverage
    RunSSCase(dir; PrintModel=true, WriteReport=false, PrintOutput=false, TestMode=true)
    @test isfile(joinpath(dir,"records/model_stats.txt"))==true
    #@test isfile(joinpath(dir,"plots/NetworkPlot.png"))==true

    # Delete everything added by the code once the tests are run; again
    rm(joinpath(dir,"_Model.txt"))
    rm(joinpath(dir,"records"), recursive=true)
    rm(joinpath(dir,"plots"), recursive=true)
end
