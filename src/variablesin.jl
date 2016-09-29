export variablesin

hash(x::AbstractExpr) = x.id_hash

# TODO memoize variables in expressions

# id2var maps variable ids to variables
function variablesin(x::Variable, id2var = Dict{UInt64, Variable}())
  myid = hash(x)
  id2var[myid] = x
  return Set{UInt64}([myid])
end
variablesin(x::Constant, id2var = Dict{UInt64, Variable}()) = Set{UInt64}()
function variablesin(x::AbstractExpr, id2var = Dict{UInt64, Variable}())
  myvars = Set{UInt64}()
  for child in x.children
    union!(myvars, variablesin(child, id2var))
  end
  myvars
end
function variablesin(x::Constraint, id2var = Dict{UInt64, Variable}())
  return union(variablesin(x.rhs, id2var), variablesin(x.lhs, id2var))
end
function variablesin(x, id2var = Dict{UInt64, Variable}())
  warn("why are you asking me this? i'm just a $(typeof(x))"); Set{UInt64}()
end

# Minkowski or outer product of sets
function outerproduct{T}(s::Set{T}, t::Set{T})
  results = Set{@compat Tuple{T,T}}()
  for si in s
    for ti in t
      union!(results, [(si, ti)])
    end
  end
  return results
end
