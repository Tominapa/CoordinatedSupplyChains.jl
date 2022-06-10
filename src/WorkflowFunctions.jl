################################################################################
### FUNCTIONS FOR RUNNING COMPLETE WORKFLOWS

function RunCSC(DataDir=pwd(); optimizer=Clp.Optimizer, UseArcLengths=true, Output=false)
    """
    A function to simplify workflow with CoordinatedSupplyChains.jl
    Inputs:
        - DataDir: the directory to a file containing case study data
        - optimizer: (optional keyword argument) an aptimizer to solve
                     a case study, e.g., Gurobi.Optimiizer; defaults to
                     Clp.Optimizer if not specified
    Returns:
        - nothing by default, all data if Output=true
    """
    # Load data
    T, N, P, Q, A, D, G, V, M, L, Subsets, Pars, CF = BuildModelData(DataDir, UseArcLengths);

    # Build model
    MOD = BuildModel(T, N, P, Q, A, D, G, V, M, L, Subsets, Pars, optimizer=optimizer)

    # Get model statistics
    ModelStats = GetModelStats(MOD)

    # Solve the case model
    SOL = SolveModel(MOD)

    # Calculate case study values determined post-model solve
    POST = PostSolveCalcs(T, N, P, Q, A, D, G, V, M, L, Subsets, Pars, SOL, CF)

    # Save solution data
    SaveSolution(DataDir, ModelStats, SOL, POST, T, N, P, Q, A, D, G, V, M, L, CF)

    # Update User
    println(PrintSpacer*"\n"*" "^19*"All Done!\n"*PrintSpacer)

    # return
    if Output
        return T, N, P, Q, A, D, G, V, M, L, Subsets, Pars, MOD, ModelStats, SOL, POST
    else
        return
    end
end