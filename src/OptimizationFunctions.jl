################################################################################
### FUNCTIONS FOR SOLVING COORDINATED SUPPLY CHAIN MODELS WITH JuMP
"""
    Output = OptimizeSSCase(A,N,P,D,S,T,L,Sets,Pars; CaseDataDirectory=pwd(), PrintModel=false, WriteReport=true, PrintOutput=true, ModelOutputFileName="_Model.txt", SolutionOutputFileName="_SolutionData.txt", PrintSpacer="*"^50)

# Arguments

A - arc structure from ImportFunctions
N - node structure from ImportFunctions
P - product structure from ImportFunctions
D - demand structure from ImportFunctions
S - supply structure from ImportFunctions
T - technology structure from ImportFunctions
L - technology site structure from ImportFunctions
Sets - structure containing additional sets from ImportFunctions
Pars - structure constaning additional parameters from ImportFunctions
CaseDataDirectory=pwd(): (optional keyword arg) file directory for supply chain case study data; defaults to current Julia directory if not specified
PrintModel=false: (optional keyword arg) Print the model to the REPL
WriteReport=true: (optional keyword arg) Write report to text
PrintOutput=true: (optional keyword arg) Print outputs to Julia REPL
ModelOutputFileName="_Model.txt": (optional keyword arg) Change the output text file name for the model
SolutionOutputFileName="_SolutionData.txt": (optional keyword arg) Change the output text file name for the solution report
PrintSpacer="*"^50: (optional keyword arg): Change the characters used to space out the report

# Returns

Output - Data strucuture with outputs from JuMP model

Stats - Data structure with statistics from JuMP model
```
Optimizes a steady state supply chain problem using data loaded by ImportFunctions()

Optional arguments (see arguments list) allow you to customize output behaviour
"""
function OptimizeSSCase(A,N,P,D,S,T,L,Sets,Pars; CaseDataDirectory=pwd(), PrintModel=false, WriteReport=true, PrintOutput=true, ModelOutputFileName="_Model.txt", SolutionOutputFileName="_SolutionData.txt", PrintSpacer="*"^50)
    ################################################################################
    ### MODEL STATEMENT
    MOD = JuMP.Model(optimizer_with_attributes(Clp.Optimizer))

    ################################################################################
    ### VARIABLES
    @variable(MOD, 0 <= s[n=N.ID,p=P.ID] <= Pars.sMAX[n,p]) # nodal supply allocation
    @variable(MOD, 0 <= d[n=N.ID,p=P.ID] <= Pars.dMAX[n,p]) # nodal demand allocation
    @variable(MOD, 0 <= sl[i=S.ID] <= S.cap[i]) # individual supplier allocation
    @variable(MOD, 0 <= dl[j=D.ID] <= D.cap[j]) # individual consumer allocation
    @variable(MOD, 0 <= f[a=A.ID,p=P.ID] <= Pars.fMAX[a,p]) # transport allocation (arc-indexed)
    @variable(MOD, 0 <= ξcon[t=T.ID,n=N.ID,q=P.ID] <= Pars.ξconMAX[t,n,q]) # tech. consumption, standard: products q in P committed
    @variable(MOD, 0 <= ξgen[t=T.ID,n=N.ID,p=P.ID] <= Pars.ξgenMAX[t,n,p]) # tech. generation, standard: products p in P produced

    ################################################################################
    ### EQUATIONS
    # nodal supply and nodal demand total equal total of individual supplies and individual demands
    @constraint(MOD, SupplyBalance[n=N.ID,p=P.ID], s[n,p] == sum(sl[i] for i in S.ID if S.node[i] == n && S.prod[i] == p))
    @constraint(MOD, DemandBalance[n=N.ID,p=P.ID], d[n,p] == sum(dl[j] for j in D.ID if D.node[j] == n && D.prod[j] == p))

    # System mass balance
    @constraint(MOD, Balance[n=N.ID,p=P.ID],
        s[n,p] + sum(f[a,p] for a in Sets.Ain[n]) + sum(ξgen[t,n,p] for t in Sets.NPt[n,p]) == 
        d[n,p] + sum(f[a,p] for a in Sets.Aout[n]) + sum(ξcon[t,n,p] for t in Sets.NQt[n,p]))

    # Conversion relationships (yield-based)
    @constraint(MOD, Conversion[n=N.ID,(t,p,q) in Sets.TPQ], ξgen[t,n,p] == Pars.α[t,p,q]*ξcon[t,n,q])

    ################################################################################
    ### OBJECTIVE
    # Cost expressions
    demand_revenue = @expression(MOD, sum(D.bid[j]*dl[j] for j in D.ID))
    supply_revenue = @expression(MOD, sum(S.bid[i]*sl[i] for i in S.ID))
    transport_cost = @expression(MOD, sum(P.transport_cost[p]*A.len[a]*f[a,p] for a in A.ID,p in P.ID))
    operating_cost = @expression(MOD, sum(ξcon[t,n,q]*T.bid[t] for t in T.ID, n in N.ID, q in P.ID if (Sets.NQT[n,q,t] && T.InputRef[t] == q)))

    # Full objective
    @objective(MOD, Max, demand_revenue - supply_revenue - transport_cost - operating_cost)

    ################################################################################
    ### DISPLAY MODEL FORMULATION
    filename = open(CaseDataDirectory*"/"*ModelOutputFileName,"w")
    print(filename, MOD)
    close(filename)
    if PrintModel
        print(MOD)
    end

    ################################################################################
    ### SOLVE AND DATA RETRIEVAL
    # Display statistics
    NumVars = length(all_variables(MOD))
    TotalIneqCons = num_constraints(MOD,AffExpr, MOI.LessThan{Float64})+num_constraints(MOD,AffExpr, MOI.GreaterThan{Float64})+num_constraints(MOD,VariableRef, MOI.LessThan{Float64})+num_constraints(MOD,VariableRef, MOI.GreaterThan{Float64})
    TotalEqCons = num_constraints(MOD,VariableRef, MOI.EqualTo{Float64})+num_constraints(MOD,AffExpr, MOI.EqualTo{Float64})
    NumVarBounds = num_constraints(MOD,VariableRef, MOI.LessThan{Float64})+num_constraints(MOD,VariableRef, MOI.GreaterThan{Float64})
    ModelIneqCons = num_constraints(MOD,AffExpr, MOI.LessThan{Float64})+num_constraints(MOD,AffExpr, MOI.GreaterThan{Float64})
    ModelEqCons = num_constraints(MOD,AffExpr, MOI.EqualTo{Float64})

    println(PrintSpacer*"\nModel statistics:")
    println("Variables: "*string(NumVars))
    println("Total inequality constraints: "*string(TotalIneqCons))
    println("Total equality constraints: "*string(TotalEqCons))
    println("Variable bounds: "*string(NumVarBounds))
    println("Model inequality constraints: "*string(ModelIneqCons))
    println("Model equality constraints: "*string(ModelEqCons))
    println(PrintSpacer)

    # Solve
    println("Solving original problem...")
    JuMP.optimize!(MOD)
    println("Primal status: "*string(primal_status(MOD)))
    println("Dual status: "*string(dual_status(MOD)))
    z_out = JuMP.objective_value(MOD)
    s_out = JuMP.value.(s)
    d_out = JuMP.value.(d)
    sl_out = JuMP.value.(sl)
    dl_out = JuMP.value.(dl)
    f_out = JuMP.value.(f)
    ξcon_out = JuMP.value.(ξcon)
    ξgen_out = JuMP.value.(ξgen)
    π_out = JuMP.dual.(Balance)

    ################################################################################
    ### PROFIT CALCULATIONS

    PhiSupply = Dict()
    for i in S.ID
        PhiSupply[i] = (π_out[S.node[i],S.prod[i]] - S.bid[i])*sl_out[i]
    end

    PhiDemand = Dict()
    for j in D.ID
        PhiDemand[j] = (D.bid[j] - π_out[D.node[j],D.prod[j]])*dl_out[j]
    end

    PhiTransport = Dict()
    π_transport = Dict()
    for a in A.ID
        for p in P.ID
            # transport prices (notation: s -> r for p)
            π_transport[a,p] = π_out[A.node_r[a],p] - π_out[A.node_s[a],p]
            # transport profits
            PhiTransport[a,p] = (π_transport[a,p] - P.transport_cost[p]*A.len[a])*f_out[a,p]
        end
    end

    PhiTech = DictInit([T.ID,N.ID],0)
    π_tech = DictInit([T.ID,N.ID],0)
    for t in T.ID
        for n in N.ID
            # technology prices
            π_tech[t,n] = sum(π_out[n,p]*T.OutputYields[t,p] for p in T.Outputs[t]) - sum(π_out[n,q]*T.InputYields[t,q] for q in T.Inputs[t])
        end
    end
    for ts in L.ID
        n = L.node[ts]
        t = L.tech[ts]
        p = T.InputRef[t]
        PhiTech[t,n] = (π_tech[t,n] - T.InputYields[t,p]*T.bid[t])*ξcon_out[t,n,p]
    end

    ################################################################################
    ### WRITE OUTPUT TO FILE AND DISPLAY TO REPL
    if WriteReport
        filename = open(CaseDataDirectory*"/"*SolutionOutputFileName,"w")
        print(filename, PrintSpacer*"\nModel statistics:")
        print(filename, "\nVariables: "*string(NumVars))
        print(filename, "\nTotal inequality constraints: "*string(TotalIneqCons))
        print(filename, "\nTotal equality constraints: "*string(TotalEqCons))
        print(filename, "\nVariable bounds: "*string(NumVarBounds))
        print(filename, "\nModel inequality constraints: "*string(ModelIneqCons))
        print(filename, "\nModel equality constraints: "*string(ModelEqCons))
        print(filename, "\n"*PrintSpacer*"\nObjective value: "*string(z_out))
        FilePrint(s_out,[N.ID,P.ID],filename,DataName="Supply values:",VarName="s")
        FilePrint(d_out,[N.ID,P.ID],filename,DataName="Demand values:",VarName="d")
        FilePrint(f_out,[A.ID,P.ID],filename,DataName="Transport values:",VarName="f")
        FilePrint(ξcon_out,[T.ID,N.ID,P.ID],filename,DataName="Consumption values:",VarName="ξcon")
        FilePrint(ξgen_out,[T.ID,N.ID,P.ID],filename,DataName="Generation values:",VarName="ξgen")
        FilePrint(π_out,[N.ID,P.ID],filename,DataName="Nodal clearing prices:",VarName="π")
        FilePrint(π_transport,[A.ID,P.ID],filename,DataName="Transport clearing prices:",VarName="π_f")
        FilePrint(π_tech,[T.ID,N.ID],filename,DataName="Technology clearing prices:",VarName="π_t")
        FilePrint(PhiDemand,[D.ID],filename,DataName="Demand profits:",VarName="Φ_d")
        FilePrint(PhiSupply,[S.ID],filename,DataName="Supply profits:",VarName="Φ_s")
        FilePrint(PhiTransport,[A.ID,P.ID],filename,DataName="Transport profits:",VarName="Φ_f")
        FilePrint(PhiTech,[T.ID,N.ID],filename,DataName="Technology profits:",VarName="Φ_ξ")
        close(filename)
    end

    # And print to REPL
    if PrintOutput
        println(PrintSpacer)
        println("Objective value: ", z_out)
        # NOTE to display all values, replace Nonzeros() with DictInit([A,B,...Z],true), or (for specific values) with a TruthTable
        PrettyPrint(s_out, [N.ID,P.ID], Nonzeros(s_out, [N.ID,P.ID]), DataName="Supply values:", VarName="s")
        PrettyPrint(d_out, [N.ID,P.ID], Nonzeros(d_out, [N.ID,P.ID]), DataName = "Demand values:", VarName="d")
        PrettyPrint(f_out, [A.ID,P.ID], Nonzeros(f_out, [A.ID,P.ID]), DataName = "Transport values:", VarName="f")
        PrettyPrint(ξcon_out, [T.ID,N.ID,P.ID], Nonzeros(ξcon_out, [T.ID,N.ID,P.ID]), DataName = "Consumption values:", VarName="ξcon")
        PrettyPrint(ξgen_out, [T.ID,N.ID,P.ID], Nonzeros(ξgen_out, [T.ID,N.ID,P.ID]), DataName = "Generation values:", VarName="ξgen")
        PrettyPrint(π_out, [N.ID,P.ID], Nonzeros(π_out, [N.ID,P.ID]), DataName = "Nodal clearing prices:", VarName="π")
        PrettyPrint(π_transport, [A.ID,P.ID], Nonzeros(π_transport, [A.ID,P.ID]), DataName = "Transport clearing prices:", VarName="π_f")
        PrettyPrint(π_tech, [T.ID,N.ID], Nonzeros(π_tech, [T.ID,N.ID]), DataName = "Technology clearing prices:", VarName="π_t")
        PrettyPrint(PhiDemand, [D.ID], Nonzeros(PhiDemand, [D.ID]), DataName = "Demand profits:", VarName="Φ_d")
        PrettyPrint(PhiSupply, [S.ID], Nonzeros(PhiSupply, [S.ID]), DataName = "Supply profits:", VarName="Φ_s")
        PrettyPrint(PhiTransport, [A.ID,P.ID], Nonzeros(PhiTransport, [A.ID,P.ID]), DataName = "Transport profits:", VarName="Φ_f")
        PrettyPrint(PhiTech, [T.ID,N.ID], Nonzeros(PhiTech, [T.ID,N.ID]), DataName = "Technology profits:", VarName="Φ_ξ")
    end

    ################################################################################
    ### PACKAGE INTO RETURN STRUCTURE
    Output = OutputStruct(z_out,sl_out,dl_out,s_out,d_out,f_out,ξcon_out,ξgen_out,π_out,π_transport,π_tech,PhiDemand,PhiSupply,PhiTransport,PhiTech);
    Stats = StatStruct(NumVars,TotalIneqCons,TotalEqCons,NumVarBounds,ModelIneqCons,ModelEqCons)

    ################################################################################
    ### UPDATE USER
    println(PrintSpacer,"\nModel Complete\n",PrintSpacer)

    ################################################################################
    ### RETURN
    return(Output,Stats);
    # e.g.: Output = OptimizeSSCase(A,N,P,D,S,T,L,Sets,Pars,CaseDataDirectory="/Users/ptominac/Documents/Code/CoordinatedSupplyChains/TestCases/TestV36");
end