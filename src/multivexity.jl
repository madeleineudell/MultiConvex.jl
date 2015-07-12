using Convex
import Convex.MultiplyAtom

export multivexity

hash(x::AbstractExpr) = x.id_hash

# TODO memoize
# id2var maps variable ids to variables
function variablesin(x::Variable, id2var = Dict{Uint64, Variable}())
  myid = hash(x)
  id2var[myid] = x
  return Set{Uint64}({myid})
end
variablesin(x::Constant, id2var = Dict{Uint64, Variable}()) = Set{Uint64}()
function variablesin(x::AbstractExpr, id2var = Dict{Uint64, Variable}())
  myvars = Set{Uint64}()
  for child in x.children
    union!(myvars, variablesin(child, id2var))
  end
  myvars
end
function variablesin(x, id2var = Dict{Uint64, Variable}())
  warn("why are you asking me this? i'm just a $(typeof(x))"); Set{Uint64}()
end

function outerproduct{T}(s::Set{T}, t::Set{T})
  results = Set{Tuple{T,T}}()
  for si in s
    for ti in t
      union!(results, (si, ti))
    end
  end
  return results
end

# multicurvature computes the curvature of the function,
# supposing ...
# records id to variable mapping and
# adds conflicts to `conflicts`
function multicurvature(x::AbstractExpr,
                        conflicts = Set{Tuple{Uint64, Uint64}}(), 
                        id2var = Dict{Uint64, Variable}())
  return curvature(x)
end

function multicurvature(x::MultiplyAtom, 
                        conflicts = Set{Tuple{Uint64, Uint64}}(), 
                        id2var = Dict{Uint64, Variable}())
  c1, c2 = x.children[1], x.children[2]
  m1, m2 = multivexity(c1, E)[1], multivexity(c2, E)[1]  
  if m1 != ConstVexity() && m2 != ConstVexity()
    # one or the other of c1 and c2 must be constant for 
    # the expression to be DCP
    # so we add the complete bipartite graph on the variables in c1 and c2 to the conflict edges E
    union!(E, outerproduct(variablesin(c1, id2var), variablesin(c2, id2var)))
  end
  return m1 + m2
end

multivexity(x::Variable, conflicts, id2var) = vexity(x)
multivexity(x::Constant, conflicts, id2var) = vexity(x)

function multivexity(x::AbstractExpr,
                     conflicts = Set{Tuple{Uint64, Uint64}}(), 
                     id2var = Dict{Uint64, Variable}())
  monotonicities = monotonicity(x)
  vex = multicurvature(x, conflicts, id2var)
  for i = 1:length(x.children)
    vex += monotonicities[i] * multivexity(x.children[i], conflicts, id2var)
  end
  return vex
end

function multivexity(x::AbstractExpr)
  conflicts = Set{Tuple{Uint64, Uint64}}()
  id2var = Dict{Uint64, Variable}()
  return multivexity(x, conflicts, id2var), conflicts, id2var
end

# a problem is multiconvex if there exists a partition of the variables 
# in the problem such that
  # 1. the objective is convex in each element of the partition holding the others constant
  # 2. all constraints are convex
  # 3. all variables participating in any constraint are in the same element of the partition
# this function checks multiconvexity of a problem 
# and returns the partition that certifies multiconvexity
function multivexity(problem::Problem)
  conflicts = Set{Tuple{Uint64, Uint64}}()
  id2var = Dict{Uint64, Variable}()
  obj_vex = multivexity(problem.objective, conflicts, id2var)
  if problem.head == :maximize
    obj_vex = -obj_vex
  end
  # the objective must be convex
  if typeof(obj_vex) == ConcaveVexity
    warn("Expression not DMCP compliant")
  end

  # the constraints must be convex and must not violate the conflicts graph
  m = length(problem.constraints)
  varpartition = Array(Set{Uint64}, m)
  activeparts = fill(true, m)
  for i=1:m
    constraint = problem.constraints[i]
    vexity(constraint) == ConvexVexity() || warn("Expression not DMCP compliant")
    vars = variablesin(constraint, id2var)
    # if the variables in two constraints intersect, 
    # the the union of their variables must be in the same partition
    for j=(1:i-1)[activeparts[1:i-1]] # for every subset known to be in the partition
      if length(intersect(varpartition[j], vars)) > 0
        union!(vars, varpartition[j])
        activeparts[j] = false
      end
    end
    varpartition[i] = vars
    activeparts[i] = true
  end
  varpartition = varpartition[activeparts]

  # check that the variables that must be simultaneously active don't violate the conflicts graph
  for i=1:length(varpartition)
    for j=1:i-1
      for (s,t) in outerproduct(varpartition[i], varpartition[j])
        if (s,t) in conflicts
          warn("Expression not DMCP compliant")
        end
      end
    end
  end

  return obj_vex, varpartition, id2var
end