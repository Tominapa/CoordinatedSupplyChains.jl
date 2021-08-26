################################################################################
### FUNCTIONS FOR EXPORTING MODEL RESULTS

function SSRecordMaker(A,N,P,D,S,T,L,Outputs,Stats; CaseDataDirectory=pwd(), PrintSpacer="*"^50)
    ################################################################################
    ### SETUP
    RecordFolder = "/records"

    # Add records folder if not present
    if !isdir(CaseDataDirectory*RecordFolder)
        mkdir(CaseDataDirectory*RecordFolder)
    end

    ################################################################################
    ### WRITE VARIABLES TO FILES

    # sl[i]
    filename = open(CaseDataDirectory*RecordFolder*"/supply.csv","w")
    print(filename, "# 1.Supply ID| 2.Node| 3.Product| 4.Variable Value")
    for i in S.ID
        print(filename, "\n"*i*"|"*S.node[i]*"|"*S.prod[i]*"|"*string(Outputs.si[i]))
    end
    close(filename)

    # dl[j]
    filename = open(CaseDataDirectory*RecordFolder*"/demand.csv","w")
    print(filename, "# 1.Demand ID| 2.Node| 3.Product| 4.Variable Value")
    for j in D.ID
        print(filename, "\n"*j*"|"*D.node[j]*"|"*D.prod[j]*"|"*string(Outputs.dj[j]))
    end
    close(filename)

    # s[n,p]
    filename = open(CaseDataDirectory*RecordFolder*"/nodal_supply.csv","w")
    print(filename, "# 1.Node| 2.Product| 3.Variable Value")
    for n in N.ID
        for p in P.ID
            print(filename, "\n"*n*"|"*p*"|"*string(Outputs.snp[n,p]))
        end
    end
    close(filename)

    # d[n,p]
    filename = open(CaseDataDirectory*RecordFolder*"/nodal_demand.csv","w")
    print(filename, "# 1.Node| 2.Product| 3.Variable Value")
    for n in N.ID
        for p in P.ID
            print(filename, "\n"*n*"|"*p*"|"*string(Outputs.dnp[n,p]))
        end
    end
    close(filename)

    # f[n,m,p]
    filename = open(CaseDataDirectory*RecordFolder*"/transport.csv","w")
    print(filename, "# 1.Arc| 2.Product| 3.Variable Value")
    for a in A.ID
        for p in P.ID
            print(filename, "\n"*a*"|"*p*"|"*string(Outputs.f[a,p]))
        end
    end
    close(filename)

    # x[t,n,q]
    filename = open(CaseDataDirectory*RecordFolder*"/consumption.csv","w")
    print(filename, "# 1.Technology| 2.Node| 3.Product| 4.Variable Value")
    for t in T.ID
        for n in N.ID
            for q in P.ID
                print(filename, "\n"*t*"|"*n*"|"*q*"|"*string(Outputs.ξcon[t,n,q]))
            end
        end
    end
    close(filename)

    # g[t,n,p]
    filename = open(CaseDataDirectory*RecordFolder*"/generation.csv","w")
    print(filename, "# 1.Technology| 2.Node| 3.Product| 4.Variable Value")
    for t in T.ID
        for n in N.ID
            for p in P.ID
                print(filename, "\n"*t*"|"*n*"|"*p*"|"*string(Outputs.ξgen[t,n,p]))
            end
        end
    end
    close(filename)

    # π[n,p]
    filename = open(CaseDataDirectory*RecordFolder*"/nodal_price.csv","w")
    print(filename, "# 1.Node| 2.Product| 3.Variable Value")
    for n in N.ID
        for p in P.ID
            print(filename, "\n"*n*"|"*p*"|"*string(Outputs.πNP[n,p]))
        end
    end
    close(filename)

    # π_transport[a,p]
    filename = open(CaseDataDirectory*RecordFolder*"/transport_price.csv","w")
    print(filename, "# 1. Arc| 2.Node 1| 3.Node 2| 4.Product| 5.Variable Value")
    for a in A.ID
        for p in P.ID
            print(filename, "\n"*a*"|"*A.node_s[a]*"|"*A.node_r[a]*"|"*p*"|"*string(Outputs.πA[a,p]))
        end
    end
    close(filename)

    # cp_tech[t,n,z]
    filename = open(CaseDataDirectory*RecordFolder*"/technology_price.csv","w")
    print(filename, "# 1.Technology| 2.Node| 3.Product| 4.Variable Value")
    for t in T.ID
        for n in N.ID
            print(filename, "\n"*t*"|"*n*"|"*string(Outputs.πT[t,n]))
        end
    end
    close(filename)

    # PhiSupply[i]
    filename = open(CaseDataDirectory*RecordFolder*"/supply_profit.csv","w")
    print(filename, "# 1.Supply ID| 2.Node| 3.Product| 4.Variable Value")
    for i in S.ID
        print(filename, "\n"*i*"|"*S.node[i]*"|"*S.prod[i]*"|"*string(Outputs.Φs[i]))
    end
    close(filename)

    # PhiDemand[i]
    filename = open(CaseDataDirectory*RecordFolder*"/demand_profit.csv","w")
    print(filename, "# 1.Demand ID| 2.Node| 3.Product| 4.Variable Value")
    for j in D.ID
        print(filename, "\n"*j*"|"*D.node[j]*"|"*D.prod[j]*"|"*string(Outputs.Φd[j]))
    end
    close(filename)

    # PhiTransport[n,m,p]
    filename = open(CaseDataDirectory*RecordFolder*"/transport_profit.csv","w")
    print(filename, "# 1. Arc| 2.Node 1| 3.Node 2| 4.Product| 5.Variable Value")
    for a in A.ID
        for p in P.ID
            print(filename, "\n"*a*"|"*A.node_s[a]*"|"*A.node_r[a]*"|"*p*"|"*string(Outputs.Φf[a,p]))
        end
    end
    close(filename)

    # PhiTech[t,n]
    filename = open(CaseDataDirectory*RecordFolder*"/technology_profit.csv","w")
    print(filename, "# 1.Technology| 2.Node| 3.Variable Value")
    for t in T.ID
        for n in N.ID
            print(filename, "\n"*t*"|"*n*"|"*string(Outputs.Φξ[t,n]))
        end
    end
    close(filename)

    # Stats
    filename = open(CaseDataDirectory*RecordFolder*"/model_stats.txt","w")
        print(filename, PrintSpacer*"\nModel statistics:")
        print(filename, "\nVariables: "*string(Stats.NumVars))
        print(filename, "\nTotal inequality constraints: "*string(Stats.TotalIneqCons))
        print(filename, "\nTotal equality constraints: "*string(Stats.TotalEqCons))
        print(filename, "\nVariable bounds: "*string(Stats.NumVarBounds))
        print(filename, "\nModel inequality constraints: "*string(Stats.ModelIneqCons))
        print(filename, "\nModel equality constraints: "*string(Stats.ModelEqCons))
        print(filename, "\n"*PrintSpacer*"\nObjective value: "*string(Outputs.z)*"\n"*PrintSpacer)
    close(filename)

    ################################################################################
    ### END OF CODE ###
    println(PrintSpacer,"\nRecords Saved!\n",PrintSpacer)
end