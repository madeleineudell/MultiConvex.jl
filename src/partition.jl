export stablepartition!, isstableset

function isstableset{T}(S::Set{T}, E::Set{@compat Tuple{T,T}})
  for (i,j) in E
    if i in S && j in S
      return false
    end
  end
  return true
end

function stablepartition!{T}(conflicts::Set{@compat Tuple{T, T}}, 
                             stablesets::Array{Set{T}, 1} = Set{T}[])

  # elements already in stablesets are already taken care of
  prepartitioned = union(stablesets...)

  # convert the set of conflicts into a dictionary
  # mapping each id to the ids of its neighbors in the graph 
  id2neighborid = Dict{T, Set{T}}() # map from variable id to neighbor ids
  for e in conflicts
    for i in 1:2
      v = e[i]
      n = e[i%2+1]
      if v in prepartitioned
        continue
      elseif !(v in keys(id2neighborid))
        # initialize v and add neighbor n
        id2neighborid[v] = Set{T}({n})
      else
        # just add neighbor n
        union!(id2neighborid[v], n)
      end
    end
  end

  # apportion variables not prepartitioned into the stable sets,
  # creating additional stable sets if necessary
  # might be better to produce a set cover with maximal stable sets,
  # but that's (NP) hard
  stablepartition!(id2neighborid, stablesets)

  return stablesets
end

# id2neighborhoodid maps node ids to the list of the node's neighbors in the graph
# returns a list of stable sets in the graph whose union is the full set of nodes
# uses a greedy algorithm
function stablepartition!{T}(id2neighborid::Dict{T, Set{T}}, 
                             stablesets::Array{Set{T}, 1} = Set{T}[])
  for varid in keys(id2neighborid)
    foundhome = false
    varid in id2neighborid[varid] && error("cannot partition graph with self loop")
    for s in stablesets
      if length(intersect(s, id2neighborid[varid])) == 0
        # var has no neighbors in s, so add it to s
        union!(s, varid)
        foundhome = true
        break
      end
    end
    if !foundhome
      # var conflicts with all previous subsets, so make a new subset
      push!(stablesets, Set{T}({varid}))
    end
  end
  return stablesets
end