################################################################################
### FUNCTIONS FOR RUNNING COMPLETE WORKFLOWS

function RunSSCase(CaseDataDirectory=pwd(); PrintModel=false, WriteReport=true, PrintOutput=true, ModelOutputFileName="_Model.txt", SolutionOutputFileName="_SolutionData.txt", PrintSpacer="*"^50)

    # Load data
    A,N,P,D,S,T,L,Sets,Pars = LoadSSCaseData(CaseDataDirectory);

    # Run steady state model
    Output, Stats = OptimizeSSCase(A,N,P,D,S,T,L,Sets,Pars,
        CaseDataDirectory=CaseDataDirectory,
        PrintModel=PrintModel,
        WriteReport=WriteReport,
        PrintOutput=PrintOutput,
        ModelOutputFileName=ModelOutputFileName,
        SolutionOutputFileName=SolutionOutputFileName,
        PrintSpacer=PrintSpacer);

    # Record results
    SSRecordMaker(A,N,P,D,S,T,L,Output,Stats,
        CaseDataDirectory=CaseDataDirectory,
        PrintSpacer=PrintSpacer);

    # Generate network plot 
    SSNetworkPlot(A,N,P,D,S,L,Output.f,
        CaseDataDirectory=CaseDataDirectory,
        PrintSpacer=PrintSpacer);

    # Update User
    println(PrintSpacer*"\nSteady State Case Done!\n"*PrintSpacer)
end