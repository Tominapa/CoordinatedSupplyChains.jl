################################################################################
### BUILD JuMP MODEL
function BuildModel(T, N, P, Q, A, D, G, V, M, L, Subsets, Pars; optimizer=DefaultOptimizer)
    """
    Builds a coordination model from data structures
    Inputs:
        - time struct (T)
        - node struct (N)
        - product struct (P)
        - impact struct (Q)
        - arc struct (A)
        - demand struct (D)
        - supply struct (G)
        - impact struct (V)
        - technology data struct (M)
        - technology mapping struct (L)
        - Subsets struct (Subsets)
        - Parameter struct (Pars)
    Outputs:
        - JuMP model (MOD)
    """
    ################################################################################
    ### MODEL STATEMENT
    MOD = JuMP.Model(optimizer)

    ################################################################################
    ### VARIABLES
    @variable(MOD, 0 <= g[i=G.ID] <= G.cap[i]) # supplier allocation by ID
    @variable(MOD, 0 <= d[j=D.ID] <= D.cap[j]) # consumer allocation by ID
    @variable(MOD, 0 <= e[v=V.ID] <= V.cap[v]) # impact allocation by ID
    @variable(MOD, 0 <= f[a=A.ID,p=P.ID] <= A.cap[a,p]) # transport allocation (arc-indexed)
    @variable(MOD, 0 <= ξ[l=L.ID] <= M.cap[L.tech[l]]) # technology allocation w.r.t. reference product
    
    ################################################################################    
    ### EQUATIONS
    # Constraint expressions
    PB_i = @expression(MOD, [n=N.ID,t=T.ID,p=P.ID], sum(g[i] for i in Subsets.Gntp[n,t,p]))
    PB_j = @expression(MOD, [n=N.ID,t=T.ID,p=P.ID], sum(d[j] for j in Subsets.Dntp[n,t,p]))
    PB_a_in = @expression(MOD, [n=N.ID,t=T.ID,p=P.ID], sum(f[a,p] for a in Subsets.Ain[n,t]))
    PB_a_out = @expression(MOD, [n=N.ID,t=T.ID,p=P.ID], sum(f[a,p] for a in Subsets.Aout[n,t]))
    PB_m_gen = @expression(MOD, [n=N.ID,t=T.ID,p=P.ID], sum(Pars.γmp[L.tech[l],p]*ξ[l] for l in Subsets.NTPgenl[n,t,p]))
    PB_m_con = @expression(MOD, [n=N.ID,t=T.ID,p=P.ID], sum(Pars.γmp[L.tech[l],p]*ξ[l] for l in Subsets.NTPconl[n,t,p]))
    
    QB_i = @expression(MOD, [n=N.ID,t=T.ID,q=Q.ID], sum(Pars.γiq[i,q]*g[i] for i in Subsets.Gntq[n,t,q]))
    QB_j = @expression(MOD, [n=N.ID,t=T.ID,q=Q.ID], sum(Pars.γjq[j,q]*d[j] for j in Subsets.Dntq[n,t,q]))
    QB_a = @expression(MOD, [n=N.ID,t=T.ID,q=Q.ID], sum(Pars.γaq[a,q]*f[a,p] for a in Subsets.Ain[n,t], p in P.ID))
    QB_m = @expression(MOD, [n=N.ID,t=T.ID,q=Q.ID], sum(Pars.γmq[L.tech[l],q]*ξ[l] for l in Subsets.NTQgenl[n,t,q]))
    QB_v = @expression(MOD, [n=N.ID,t=T.ID,q=Q.ID], sum(e[v] for v in Subsets.Vntq[n,t,q]))
    
    # Constraints
    @constraint(MOD, ProductBalance[n=N.ID,t=T.ID,p=P.ID],
        PB_i[n,t,p] + PB_a_in[n,t,p] + PB_m_gen[n,t,p] - PB_j[n,t,p] - PB_a_out[n,t,p] - PB_m_con[n,t,p] == 0)

    @constraint(MOD, ImpactBalance[n=N.ID,t=T.ID,q=Q.ID],
        QB_i[n,t,q] + QB_j[n,t,q] + QB_a[n,t,q] + QB_m[n,t,q] - QB_v[n,t,q] == 0)
    
    # Objective function expressions
    demand_obj = @expression(MOD, sum(D.bid[j]*d[j] for j in D.ID))
    supply_obj = @expression(MOD, sum(G.bid[i]*g[i] for i in G.ID))
    env_obj = @expression(MOD, sum(V.bid[v]*e[v] for v in V.ID))
    transport_obj = @expression(MOD, sum(A.bid[a,p]*f[a,p] for a in A.ID, p in P.ID))
    technology_obj = @expression(MOD, sum(M.bid[L.tech[l]]*ξ[l] for l in L.ID))
    
    # Objective function
    @objective(MOD, Max, demand_obj + env_obj - supply_obj - transport_obj - technology_obj)

    # Return
    return MOD
end

################################################################################
### ASSEMBLE MODEL STATISTICS
function GetModelStats(MOD, DisplayMode=true)#, PrintSpacer="*"^50)
    ### Calculate statistics
    NumVars = length(all_variables(MOD))
    TotalIneqCons = num_constraints(MOD,AffExpr, MOI.LessThan{Float64})+num_constraints(MOD,AffExpr, MOI.GreaterThan{Float64})+num_constraints(MOD,VariableRef, MOI.LessThan{Float64})+num_constraints(MOD,VariableRef, MOI.GreaterThan{Float64})
    TotalEqCons = num_constraints(MOD,VariableRef, MOI.EqualTo{Float64})+num_constraints(MOD,AffExpr, MOI.EqualTo{Float64})
    NumVarBounds = num_constraints(MOD,VariableRef, MOI.LessThan{Float64})+num_constraints(MOD,VariableRef, MOI.GreaterThan{Float64})
    ModelIneqCons = num_constraints(MOD,AffExpr, MOI.LessThan{Float64})+num_constraints(MOD,AffExpr, MOI.GreaterThan{Float64})
    ModelEqCons = num_constraints(MOD,AffExpr, MOI.EqualTo{Float64})

    ### Optional: display statistics to REPL
    if DisplayMode # default true
        println(PrintSpacer*"\nModel statistics:")
        println("Variables: "*string(NumVars))
        println("Total inequality constraints: "*string(TotalIneqCons))
        println("Total equality constraints: "*string(TotalEqCons))
        println("Variable bounds: "*string(NumVarBounds))
        println("Model inequality constraints: "*string(ModelIneqCons))
        println("Model equality constraints: "*string(ModelEqCons))
        println(PrintSpacer)
    end

    ### Return
    return ModelStatStruct(NumVars,TotalIneqCons,TotalEqCons,NumVarBounds,ModelIneqCons,ModelEqCons)
end

################################################################################
### SOLVE JuMP MODEL
function SolveModel(MOD)
    """
    Solves JuMP coordination model MOD and returns solution structure with variable values
    Inputs:
        - JuMP coordination model (MOD)
    Outputs:
        - solution data struct (SOL)
    """
    ### Solve & print status to REPL
    println("Solving original problem...")
    JuMP.optimize!(MOD)
    println("Termination status: "*string(termination_status(MOD)))
    println("Primal status: "*string(primal_status(MOD)))
    println("Dual status: "*string(dual_status(MOD)))

    ### Get results
    z_out = JuMP.objective_value(MOD)
    g_out = JuMP.value.(MOD[:g])
    d_out = JuMP.value.(MOD[:d])
    e_out = JuMP.value.(MOD[:e])
    f_out = JuMP.value.(MOD[:f])
    ξ_out = JuMP.value.(MOD[:ξ])
    π_p_out = JuMP.dual.(MOD[:ProductBalance])
    π_q_out = JuMP.dual.(MOD[:ImpactBalance])
    
    ###  Return
    return SolutionStruct(string(termination_status(MOD)),string(primal_status(MOD)),string(dual_status(MOD)),z_out,g_out,d_out,e_out,f_out,ξ_out,π_p_out,π_q_out)
end

################################################################################
### CALCULATE ADDITIONAL SOLUTION VALUES
function PostSolveCalcs(T, N, P, Q, A, D, G, V, M, L, Subsets, Pars, SOL, CF)
    """
    Calculates post-solve parameter values
    Inputs:
    Outputs:
    """
    ### determine nodal supply, demand, environmental consumption
    gNTP = DictInit([N.ID,T.ID,P.ID], 0.0)
    dNTP = DictInit([N.ID,T.ID,P.ID], 0.0)
    eNTQ = DictInit([N.ID,T.ID,Q.ID], 0.0)
    for n in N.ID
        for t in T.ID
            for p in P.ID
                if Subsets.Gntp[n,t,p] != []
                    gNTP[n,t,p] = sum(SOL.g[i] for i in Subsets.Gntp[n,t,p])
                end
                if Subsets.Dntp[n,t,p] != [] 
                    dNTP[n,t,p] = sum(SOL.d[j] for j in Subsets.Dntp[n,t,p])
                end
            end
            for q in Q.ID
                if Subsets.Vntq[n,t,q] != []
                    eNTQ[n,t,q] = sum(SOL.e[v] for v in Subsets.Vntq[n,t,q])
                end
            end
        end
    end

    ### determine consumption/generation values based on ξ[l]
    ξgen = DictInit([L.ID,P.ID], 0.0)
    ξcon = DictInit([L.ID,P.ID], 0.0)
    ξenv = DictInit([L.ID,Q.ID], 0.0)
    for l in L.ID
        for p in M.Outputs[L.tech[l]]
            ξgen[l,p] = M.OutputYields[L.tech[l],p]*SOL.ξ[l]
        end
        for p in M.Inputs[L.tech[l]]
            ξcon[l,p] = M.InputYields[L.tech[l],p]*SOL.ξ[l]
        end
        for q in M.Impacts[L.tech[l]]
            ξenv[l,q] = M.ImpactYields[L.tech[l],q]*SOL.ξ[l]
        end
    end
    
    ### calculate supply and demand impact values (prices)
    # Supplier impact value
    π_iq = DictInit([G.ID,Q.ID], 0.0)
    for i in Subsets.GQ
        for q in G.Impacts[i]
            π_iq[i,q] = Pars.γiq[i,q]*SOL.πq[G.node[i],G.time[i],q]
        end
    end

    # Consumer impact value
    π_jq = DictInit([D.ID,Q.ID], 0.0)
    for j in Subsets.DQ
        for q in D.Impacts[j]
            π_jq[j,q] = Pars.γjq[j,q]*SOL.πq[D.node[j],D.time[j],q]
        end
    end

    ### calculate transport and technology price values
    # transportation price
    π_a = DictInit([A.ID,P.ID], 0.0)
    # transportation price associated with impact q ∈ Q
    π_aq = DictInit([A.ID,Q.ID], 0.0)
    for a in A.ID
        for p in P.ID
            π_a[a,p] = SOL.πp[A.n_recv[a],A.t_recv[a],p] - SOL.πp[A.n_send[a],A.t_send[a],p]
        end
        for q in Q.ID
            π_aq[a,q] = Pars.γaq[a,q]*SOL.πq[A.n_recv[a],A.t_recv[a],q]
        end
    end

    # technology price
    π_m = DictInit([M.ID,N.ID,T.ID], 0.0)
    # technology price associated with impact q ∈ Q
    π_mq = DictInit([M.ID,N.ID,T.ID,Q.ID], 0.0)
    for m in M.ID
        for n in N.ID
            for t in T.ID
                π_m[m,n,t] = sum(Pars.γmp[m,p]*SOL.πp[n,t,p] for p in M.Outputs[m]) - sum(Pars.γmp[m,p]*SOL.πp[n,t,p] for p in M.Inputs[m])    
                for q in M.Impacts[m]
                    π_mq[m,n,t,q] = Pars.γmq[m,q]*SOL.πq[n,t,q]
                end
            end
        end
    end

    ### Profits
    # Supplier profits
    ϕi = DictInit([G.ID], 0.0)
    for i in G.ID
        ϕi[i] = (SOL.πp[G.node[i],G.time[i],G.prod[i]] + reduce(+,π_iq[i,q] for q in G.Impacts[i];init=0) - G.bid[i])*SOL.g[i]
    end

    # Consumer profits
    ϕj = DictInit([D.ID], 0.0)
    for j in D.ID
        ϕj[j] = (D.bid[j] - SOL.πp[D.node[j],D.time[j],D.prod[j]] + reduce(+,π_jq[j,q] for q in D.Impacts[j];init=0))*SOL.d[j]
    end

    # Environmental consumer profits
    ϕv = DictInit([V.ID], 0.0)
    for v in V.ID
        ϕv[v] = (V.bid[v] - SOL.πq[V.node[v],V.time[v],V.impact[v]])*SOL.e[v]
    end

    # Technology profits, by techmap index
    ϕl = DictInit([L.ID], 0.0)
    for l in L.ID
        m = L.tech[l]
        n = L.node[l]
        t = L.time[l]
        ϕl[l] = (π_m[m,n,t] + reduce(+,π_mq[m,n,t,q] for q in M.Impacts[m];init=0) - M.bid[m])*SOL.ξ[l]
    end

    # Transportation profits
    ϕa = DictInit([A.ID,P.ID], 0.0)
    for a in A.ID
        for p in P.ID
            ϕa[a,p] = (π_a[a,p] + sum(π_aq[a,q] for q in Q.ID) - A.bid[a,p])*SOL.f[a,p]
        end
    end

    ### Return
    return PostSolveValues(gNTP, dNTP, eNTQ, ξgen, ξcon, ξenv, π_iq, π_jq, π_a, π_aq, π_m, π_mq, ϕi, ϕj, ϕv, ϕl, ϕa)
end

################################################################################
### SAVE SOLUTION TO FILE
function SaveSolution(filedir, ModelStats, SOL, POST, T, N, P, Q, A, D, G, V, M, L, CF)
    """
    Saves the solution from a JuMP model to a text file
    Inputs:
        - filedir -> location for case study
        - JuMP solution struct (SOL)
        - JuMP model statistics (ModelStats)
        - Post-solve calculation struct (POST)
        - Set structures: T, N, P, Q, A, D, G, V, M, L
    Outputs:
        - returns nothing
    """
    ### Create solution directory if not present
    SolutionDir = joinpath(filedir, "_SolutionData")
    if !isdir(SolutionDir)
        mkdir(SolutionDir)
    end

    ### Write solution data to one single text file
    SolutionFile = joinpath(SolutionDir, "_SolutionData.txt")
    solution = open(SolutionFile, "w")
        # print solution stats to file
        print(solution, PrintSpacer*"\nTermination status: "*string(SOL.TermStat))
        print(solution, "\nPrimal status: "*string(SOL.PrimalStat))
        print(solution, "\nDual status: "*string(SOL.DualStat))
        print(solution, "\n"*PrintSpacer*"\nNumber of variables: "*string(ModelStats.Variables))
        print(solution, "\nTotal inequality constraints: "*string(ModelStats.TotalInequalityConstraints))
        print(solution, "\nTotal equality constraints: "*string(ModelStats.TotalEqualityConstraints))
        print(solution, "\nNumber of variable bounds: "*string(ModelStats.VariableBounds))
        print(solution, "\nModel inequality constraints: "*string(ModelStats.ModelInequalityConstrtaints))
        print(solution, "\nModel equality constraints: "*string(ModelStats.ModelEqualityConstraints))
        # print solution data to file
        print(solution, "\n"*PrintSpacer*"\nObjective value: "*string(SOL.z))
        FilePrint(SOL.g,[G.ID],solution;Header=PrintSpacer,DataName="Supply Allocations:",VarName="g")
        FilePrint(SOL.d,[D.ID],solution;Header=PrintSpacer,DataName="Demand Allocations:",VarName="d")
        if CF.UseImpacts
            FilePrint(SOL.e,[V.ID],solution;Header=PrintSpacer,DataName="Environmental Consumption Allocations:",VarName="e")
        end
        if CF.UseArcs
            FilePrint(SOL.f,[A.ID,P.ID],solution;Header=PrintSpacer,DataName="Transport Allocations:",VarName="f")
        end
        if CF.UseTechs
            FilePrint(SOL.ξ,[L.ID],solution;Header=PrintSpacer,DataName="Technology Allocations:",VarName="ξ")
        end
        FilePrint(SOL.πp,[N.ID,T.ID,P.ID],solution;Header=PrintSpacer,DataName="Nodal Product Prices:",VarName="π")
        if CF.UseImpacts
            FilePrint(SOL.πq,[N.ID,T.ID,Q.ID],solution;Header=PrintSpacer,DataName="Nodal Impact Prices:",VarName="π")
        end
        FilePrint(POST.gNTP,[N.ID,T.ID,P.ID],solution;Header=PrintSpacer,DataName="Nodal Supply Allocations:",VarName="g")
        FilePrint(POST.dNTP,[N.ID,T.ID,P.ID],solution;Header=PrintSpacer,DataName="Nodal Demand Allocations:",VarName="d")
        if CF.UseImpacts
            FilePrint(POST.eNTQ,[N.ID,T.ID,Q.ID],solution;Header=PrintSpacer,DataName="Nodal Environmental Allocations:",VarName="e")
        end
        if CF.UseTechs
            FilePrint(POST.ξgen,[L.ID,P.ID],solution;Header=PrintSpacer,DataName="Technology Generation Allocations:",VarName="ξgen")
            FilePrint(POST.ξcon,[L.ID,P.ID],solution;Header=PrintSpacer,DataName="Technology Consumption Allocations:",VarName="ξcon")
            if CF.UseImpacts
                FilePrint(POST.ξenv,[L.ID,Q.ID],solution;Header=PrintSpacer,DataName="Technology Impact Allocations:",VarName="ξenv")
            end
        end
        if CF.UseImpacts
            FilePrint(POST.π_iq,[G.ID,Q.ID],solution;Header=PrintSpacer,DataName="Supply Impact Prices:",VarName="π_iq")
            FilePrint(POST.π_jq,[D.ID,Q.ID],solution;Header=PrintSpacer,DataName="Demand Impact Prices:",VarName="π_jq")
        end
        if  CF.UseArcs
            FilePrint(POST.π_a,[A.ID,P.ID],solution;Header=PrintSpacer,DataName="Transport Prices:",VarName="π_a")
            if CF.UseImpacts
                FilePrint(POST.π_aq,[A.ID,Q.ID],solution;Header=PrintSpacer,DataName="Transport Impact Prices:",VarName="π_aq")
            end
        end
        if CF.UseTechs
            FilePrint(POST.π_m,[M.ID,N.ID,T.ID],solution;Header=PrintSpacer,DataName="Technology Prices:",VarName="π_m")
            if CF.UseImpacts
                FilePrint(POST.π_mq,[M.ID,N.ID,T.ID,Q.ID],solution;Header=PrintSpacer,DataName="Technology Impact Prices:",VarName="π_mq")
            end
        end
        FilePrint(POST.ϕi,[G.ID],solution;Header=PrintSpacer,DataName="Supply Profits:",VarName="ϕi")
        FilePrint(POST.ϕj,[D.ID],solution;Header=PrintSpacer,DataName="Demand Profits:",VarName="ϕj")
        if CF.UseImpacts
            FilePrint(POST.ϕv,[V.ID],solution;Header=PrintSpacer,DataName="Environmental Consumer Profits:",VarName="ϕv")
        end
        if CF.UseTechs
            FilePrint(POST.ϕl,[L.ID],solution;Header=PrintSpacer,DataName="Technology Profits:",VarName="ϕl")
        end
        if CF.UseArcs
            FilePrint(POST.ϕa,[A.ID,P.ID],solution;Header=PrintSpacer,DataName="Transport Profits:",VarName="ϕa")
        end
    close(solution)

    ### Write individual variables to csv files for easy access
    # delimiter
    Δ = ","

    # supply
    filename = open(joinpath(SolutionDir, "supply_allocations.csv"), "w")
        print(filename, "Supply ID"*Δ*"Supply node"*Δ*"Supply time"*Δ*"Supply Product"*Δ*"Supply allocation"*Δ*"Supply Profit")
        for i in G.ID
            print(filename, "\n"*i*Δ*G.node[i]*Δ*G.time[i]*Δ*G.prod[i]*Δ*string(SOL.g[i])*Δ*string(POST.ϕi[i]))
        end
    close(filename)

    # demand
    filename = open(joinpath(SolutionDir, "demand_allocations.csv"), "w")
        print(filename, "Demand ID"*Δ*"Demand node"*Δ*"Demand time"*Δ*"Demand product"*Δ*"Demand allocation"*Δ*"Consumer Profit")
        for j in D.ID
            print(filename, "\n"*j*Δ*D.node[j]*Δ*D.time[j]*Δ*D.prod[j]*Δ*string(SOL.d[j])*Δ*string(POST.ϕj[j]))
        end
    close(filename)

    # environmental consumption
    if CF.UseImpacts
        filename = open(joinpath(SolutionDir, "env_con_allocations.csv"), "w")
            print(filename, "Environmental Consumer ID"*Δ*"node"*Δ*"time"*Δ*"impact"*Δ*"Environmental Consumer allocation"*Δ*"Environmental Consumer Profit")
            for v in V.ID
                print(filename, "\n"*v*Δ*V.node[v]*Δ*V.time[v]*Δ*V.impact[v]*Δ*string(SOL.e[v])*Δ*string(POST.ϕv[v]))
            end
        close(filename)
    end

    # transportation
    if CF.UseArcs
        filename = open(joinpath(SolutionDir, "transport_allocations.csv"), "w")
            header = "Arc ID"*Δ*"Send node"*Δ*"Receiving node"*Δ*"Send time"*Δ*"Receiving time"
            for p in P.ID
                header *= Δ*"Product: "*p
            end
            for p in P.ID
                header *= Δ*"Product "*p*" transport profit"
            end
            print(filename, header)
            for a in A.ID
                print(filename, "\n"*a*Δ*A.n_send[a]*Δ*A.n_recv[a]*Δ*A.t_send[a]*Δ*A.t_recv[a])
                for p in P.ID
                    print(filename, Δ*string(SOL.f[a,p]))
                end
                for p in P.ID
                    print(filename, Δ*string(POST.ϕa[a,p]))
                end
            end
        close(filename)
    end

    # technology
    if CF.UseTechs
        filename = open(joinpath(SolutionDir, "technology_allocations.csv"), "w")
            header = "Technology ID"*Δ*"Node"*Δ*"Time"*Δ*"Reference Product"
            for p in P.ID
                header *= Δ*"Consumed: "*p
            end
            for p in P.ID
                header *= Δ*"Generated: "*p
            end
            for q in Q.ID
                header *= Δ*"Impact: "*q
            end
            header *= Δ*"Profit"
            print(filename, header)
            for l in L.ID
                print(filename, "\n"*l*Δ*L.node[l]*Δ*L.time[l]*Δ*M.InputRef[L.tech[l]])
                for p in P.ID
                    if p in M.Inputs[L.tech[l]]
                        print(filename, Δ*string(POST.ξcon[l,p]))
                    else
                        print(filename, Δ)
                    end
                end
                for p in P.ID
                    if p in M.Outputs[L.tech[l]]
                        print(filename, Δ*string(POST.ξgen[l,p]))
                    else
                        print(filename, Δ)
                    end
                end
                if CF.UseImpacts
                    for q in Q.ID
                        if q in M.Impacts[L.tech[l]]
                            print(filename, Δ*string(POST.ξenv[l,q]))
                        else
                            print(filename, Δ)
                        end
                    end
                end
                print(filename, Δ*string(POST.ϕl[l]))
            end 
        close(filename)
    end

    # nodal supply
    filename = open(joinpath(SolutionDir, "nodal_supply_allocations.csv"), "w")
        print(filename, "Node"*Δ*"Time point"*Δ*"Product"*Δ*"Total Supply")
        for n in N.ID
            for t in T.ID
                for p in P.ID
                    if POST.gNTP[n,t,p] != 0
                        print(filename, "\n"*n*Δ*t*Δ*p*Δ*string(POST.gNTP[n,t,p]))
                    end
                end
            end
        end
    close(filename)

    # nodal demand
    filename = open(joinpath(SolutionDir, "nodal_demand_allocations.csv"), "w")
        print(filename, "Node"*Δ*"Time point"*Δ*"Product"*Δ*"Total Demand")
        for n in N.ID
            for t in T.ID
                for p in P.ID
                    if POST.dNTP[n,t,p] != 0
                        print(filename, "\n"*n*Δ*t*Δ*p*Δ*string(POST.dNTP[n,t,p]))
                    end
                end
            end
        end
    close(filename)

    # nodal environmental consumption
    if CF.UseImpacts
        filename = open(joinpath(SolutionDir, "nodal_env_con_allocations.csv"), "w")
            print(filename, "Node"*Δ*"Time point"*Δ*"Product"*Δ*"Total Environmental Consumption")
            for n in N.ID
                for t in T.ID
                    for q in Q.ID
                        if POST.eNTQ[n,t,q] != 0
                            print(filename, "\n"*n*Δ*t*Δ*q*Δ*string(POST.eNTQ[n,t,q]))
                        end
                    end
                end
            end
        close(filename)
    end

    # Nodal prices
    filename = open(joinpath(SolutionDir, "nodal_prices.csv"), "w")
        print(filename, "Node"*Δ*"Time point"*Δ*"Product/Impact"*Δ*"Nodal price")
        for n in N.ID
            for t in T.ID
                for p in P.ID
                    print(filename, "\n"*n*Δ*t*Δ*p*Δ*string(SOL.πp[n,t,p]))
                end
                if CF.UseImpacts
                    for q in Q.ID
                        print(filename, "\n"*n*Δ*t*Δ*q*Δ*string(SOL.πq[n,t,q]))
                    end   
                end
            end
        end    
    close(filename)

    # supply impact prices
    if CF.UseImpacts
        filename = open(joinpath(SolutionDir, "supply_impact_prices.csv"), "w")
            print(filename, "Supplier"*Δ*"Node"*Δ*"Time point"*Δ*"Impact"*Δ*"Supply Impact Price")
            for i in G.ID
                for q in G.Impacts[i]
                    print(filename, "\n"*i*Δ*G.node[i]*Δ*G.time[i]*Δ*q*Δ*string(POST.π_iq[i,q]))
                end
            end
        close(filename)
    end

    # demand impact prices
    if CF.UseImpacts
        filename = open(joinpath(SolutionDir, "demand_impact_prices.csv"), "w")
            print(filename, "Consumer"*Δ*"Node"*Δ*"Time point"*Δ*"Impact"*Δ*"Demand Impact Price")
            for j in D.ID
                for q in D.Impacts[j]
                    print(filename, "\n"*j*Δ*D.node[j]*Δ*D.time[j]*Δ*q*Δ*string(POST.π_jq[j,q]))
                end
            end
        close(filename)
    end

    # transportation prices
    if CF.UseArcs
        filename = open(joinpath(SolutionDir, "transport_prices.csv"), "w")
            header = "Arc ID"*Δ*"Send node"*Δ*"Receiving node"*Δ*"Send time"*Δ*"Receiving time"
            for p in P.ID
                header *= Δ*"Product "*p*" transport price"
            end
            if CF.UseImpacts
                for q in Q.ID
                    header *= Δ*"Impact "*q*" transport price"
                end
            end
            print(filename, header)
            for a in A.ID
                print(filename, "\n"*a*Δ*A.n_send[a]*Δ*A.n_recv[a]*Δ*A.t_send[a]*Δ*A.t_recv[a])
                for p in P.ID
                    print(filename, Δ*string(POST.π_a[a,p]))
                end
                if CF.UseImpacts
                    for q in Q.ID
                        print(filename, Δ*string(POST.π_aq[a,q]))
                    end
                end
            end
        close(filename)
    end

    # technology prices
    if CF.UseTechs
        filename = open(joinpath(SolutionDir, "technology_prices.csv"), "w")
            header = "Technology ID"*Δ*"Node"*Δ*"Time"*Δ*"Reference Product"*Δ*"Technology Price"
            if CF.UseImpacts
                for q in Q.ID
                    header *= Δ*"Impact: "*q*" price"
                end
            end
            print(filename, header)
            for l in L.ID
                print(filename, "\n"*l*Δ*L.node[l]*Δ*L.time[l]*Δ*M.InputRef[L.tech[l]]*Δ*string(POST.π_m[L.tech[l],L.node[l],L.time[l]]))
                if CF.UseImpacts
                    for q in Q.ID
                        if q in M.Impacts[L.tech[l]]
                            print(filename, Δ*string(POST.π_mq[L.tech[l],L.node[l],L.time[l],q]))
                        else
                            print(filename, Δ)
                        end
                    end
                end
            end 
        close(filename)
    end

    ### Return
    return
end