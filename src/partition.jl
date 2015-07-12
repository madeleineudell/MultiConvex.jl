export partition!

function partition!(E::Array{Tuple, 1})
  
  # convert the list of edges E into a dictionary
  # mapping each vertex id to the ids of its neighbors in the graph 
  id2var = Dict{Uint64, Variable}() # map from variable id to variable
  id2neighborid = Dict{Uint64, Set{Uint64}}() # map from variable id to neighbor ids
  for e in E
    for i in 1:2
      v = e[i]
      n = e[i%2+1]
      if !(hash(v) in keys(id2var))
        # initialize v and add neighber n
        id2var[hash(v)] = v
        id2neighborid[hash(v)] = Set{Uint64}({hash(n)})
      else
        # just add neighbor n
        union!(id2neighborid[hash(v)], hash(n))
      end
    end
  end

  # partition variables in E into a set cover of stable sets
  # might be better to produce a set cover with maximal stable sets,
  # but that's (NP) hard
  stablesetids = partition(id2neighborid)

  # make list of vars and stablesets by Variable rather than by id
  vars = Variable[id2var[id] for id in keys(id2var)]
  stablesets = Array{Variable,1}[Variable[id2var[id] for id in s] for s in stablesetids]
  return vars, stablesets
end

# id2neighborhoodid maps node ids to the list of the node's neighbors in the graph
# returns a list of stable sets in the graph whose union is the full set of nodes
# uses a greedy algorithm
function partition(id2neighborid::Dict)
  stablesetids = Set{Uint64}[]
  for varid in keys(id2neighborid)
    foundhome = false
    varid in id2neighborid[varid] && error("cannot partition graph with self loop")
    for s in stablesetids
      if length(intersect(s, id2neighborid[varid])) == 0
        # var has no neighbors in s, so add it to s
        union!(s, varid)
        foundhome = true
        break
      end
    end
    if !foundhome
      # var conflicts with all previous subsets, so make a new subset
      push!(stablesetids, Set{Uint64}({varid}))
    end
  end
  return stablesetids
end