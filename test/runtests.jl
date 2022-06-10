using CoordinatedSupplyChains
using Test

@testset "CoordinatedSupplyChains.jl" begin
    # Test directory and file directory information
    TestFolder = "ExtendedTestSets"
    TestList = ["NoArcs",
                "NoTechnologies",
                "NoTimeNoArcsNoImpsNoTechs",
                "NutrientModelDemandLoss",
                "NutrientModelDemandLossV2",
                "TutorialModel"]
    SolutionDirectory = "_SolutionData"
    SolutionFileName = "_SolutionData.txt"

    # Keyword options
    UseArcsForTest = [true,true,true,true,true,false]

    # Run through the six test cases
    for i = 1:length(TestList)
        RunCSC(joinpath(@__DIR__,TestFolder,TestList[i]),UseArcLengths=UseArcsForTest[i])
        @test isfile(joinpath(@__DIR__,TestFolder,TestList[i],SolutionDirectory,SolutionFileName)) == true
        rm(joinpath(@__DIR__,TestFolder,TestList[i],SolutionDirectory,SolutionFileName), recursive=true)
    end
end
