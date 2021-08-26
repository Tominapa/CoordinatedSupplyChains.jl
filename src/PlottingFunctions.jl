################################################################################
### FUNCTIONS FOR PREPACKAGED PLOTS
"""
    SSNetworkPlot(A,N,P,D,S,L,f; CaseDataDirectory=pwd(), PrintSpacer="*"^50)

# Arguments

A - arc structure from ImportFunctions
N - node structure from ImportFunctions
P - product structure from ImportFunctions
D - demand structure from ImportFunctions
S - supply structure from ImportFunctions
L - technology site structure from ImportFunctions
f - transportation flows from JuMP model output structure; Output.f
CaseDataDirectory=pwd(): (optional keyword arg) file directory for supply chain case study data; defaults to current Julia directory if not specified
PrintSpacer="*"^50: (optional keyword arg): Change the characters used to space out the report
```
A simple network plot showing nodes, arcs, stakeholders, and product flows
"""
function SSNetworkPlot(A,N,P,D,S,L,f; CaseDataDirectory=pwd(), PrintSpacer="*"^50)
    ################################################################################
    ### CHECK FOR OUTPUT DIRECTORY
    PlotFolder = "/plots"

    # Add records folder if not present
    if !isdir(CaseDataDirectory*PlotFolder)
        mkdir(CaseDataDirectory*PlotFolder)
    end
    
    ################################################################################
    ### SPECS
    fig_w = 600
    fig_h = 600
    dlb = false # default legend boolean
    dfs = 12 # default font size
    dlw = 5 # default line weight
    dlc = :black # default line color
    dms = 5 # default marker size
    dmc = :white # default marker color
    dmsw = 5 # default marker stroke weight
    dmsc = :black # default marker stroke color

    # Node custom settings
    nms = 13 # node marker size

    # Transport custom settings
    tlw = 2 # tranposrt line weight
    tlc = :white # transport line color

    # Supplier custom settings
    sms = 11 # supplier marker size
    smc = :red # supplier marker color
    smsw = 1 # supplier marker stroke weight
    smsc = :white # supplier marker stroke color

    # Technology custom settings
    lms = 8 # technology marker size
    lmc = :gold # technology marker color
    lmsw = 1 # technology marker stroke weight
    lmsc = :white # technology marker stroke color

    # Consumer custom settings
    cms = 5 # consumer marker size
    cmc = :blue # consumer marker color
    cmsw = 1 # consumer marker stroke weight
    cmsc = :white # consumer marker stroke color

    ################################################################################
    ### SETUP NODES AND ARCS ON BASE PLOT
    # Arrays for arc longitudes and lattitudes; these will be fed into plot()
    Alons = []
    Alats = []
    for a in A.ID
        push!(Alons,[N.lon[A.node_s[a]],N.lon[A.node_r[a]]])
        push!(Alats,[N.lat[A.node_s[a]],N.lat[A.node_r[a]]])
    end
    plt = plot(Alons,Alats,
        color = dlc,
        lw = dlw,
        legend = dlb)

    # Arrays for node longitudes and lattitudes; these will be fed into plot()
    Nlons = []
    Nlats = []
    for n in N.ID
        push!(Nlons, N.lon[n])
        push!(Nlats, N.lat[n])
    end
    scatter!(Nlons,Nlats,
        ms = nms,
        mc = dmc,
        msw = dmsw,
        msc = dmsc,
        legend = dlb)

    ################################################################################
    ### PLOT FLOWS (SO THEY APPEAR UNDER STAKEHOLDER NODES)
    flons = []
    flats = []
    for a in A.ID
        for p in P.ID
            if f[a,p] > 0
                push!(flons,[N.lon[A.node_s[a]],N.lon[A.node_r[a]]])
                push!(flats,[N.lat[A.node_s[a]],N.lat[A.node_r[a]]])
            end
        end
    end
    plot!(flons,flats,
        arrow=(:closed, 2.0),
        color = tlc,
        lw = tlw,
        legend = dlb)

    
    ################################################################################
    ### PLOT SUPPLIER, TECHNOLOGY, CONSUMER LOCATIONS & FLOWS (IN THAT ORDER!)
    # Suppliers
    Slons = []
    Slats = []
    for i in S.ID
        push!(Slons, N.lon[S.node[i]])
        push!(Slats, N.lat[S.node[i]])
    end
    scatter!(Slons,Slats,
        ms = sms,
        mc = smc,
        msw = smsw,
        msc = smsc,
        legend = dlb)

    # Technologies
    Llons = []
    Llats = []
    for l in L.ID
        push!(Llons, N.lon[L.node[l]])
        push!(Llats, N.lat[L.node[l]])
    end
    scatter!(Llons,Llats,
        ms = lms,
        mc = lmc,
        msw = lmsw,
        msc = lmsc,
        legend = dlb)

    # Consumers
    Dlons = []
    Dlats = []
    for j in D.ID
        push!(Dlons, N.lon[D.node[j]])
        push!(Dlats, N.lat[D.node[j]])
    end
    scatter!(Dlons,Dlats,
        ms = cms,
        mc = cmc,
        msw = cmsw,
        msc = cmsc,
        legend = dlb)
    
    # Update settings
    plot!(size=(fig_w,fig_h),lims=:round)

    ################################################################################
    ### SAVE PLOT
    savefig(plt,CaseDataDirectory*PlotFolder*"/NetworkPlot.png")

    ################################################################################
    ### END OF CODE ###
    println(PrintSpacer,"\nPlot Saved to "*CaseDataDirectory*PlotFolder*"!\n",PrintSpacer)
end