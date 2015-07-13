import Convex.MultiplyAtom

export multivexity

type MultiAffineVexity <: Vexity             end
type MultiConvexVexity <: Vexity             end
type MultiConcaveVexity <: Vexity            end

multi(v::ConvexVexity) = MultiConvexVexity()

# notes:
# * may add conflicts twice since (x,y) is different (as a tuple) from (y,x)

# multicurvature computes the curvature of the function,
# supposing ...
# records id to variable mapping and
# adds conflicts to `conflicts`
function multicurvature(x::AbstractExpr,
                        conflicts = Set{@compat Tuple{Uint64, Uint64}}(), 
                        id2var = Dict{Uint64, Variable}())
  return curvature(x)
end

function multicurvature(x::MultiplyAtom, 
                        conflicts = Set{@compat Tuple{Uint64, Uint64}}(), 
                        id2var = Dict{Uint64, Variable}())
  c1, c2 = x.children[1], x.children[2]
  m1 = multivexity(c1, conflicts, id2var)
  m2 = multivexity(c2, conflicts, id2var) 
  if m1 != ConstVexity() && m2 != ConstVexity()
    # one or the other of c1 and c2 must be constant for 
    # the expression to be DCP
    # so we add the complete bipartite graph on the variables in c1 and c2 to the conflict edges E
    union!(conflicts, outerproduct(variablesin(c1, id2var), variablesin(c2, id2var)))
  end
  return m1 + m2
end

multivexity(x::Variable, conflicts, id2var) = vexity(x)
multivexity(x::Constant, conflicts, id2var) = vexity(x)

function multivexity(x::AbstractExpr,
                     conflicts = Set{@compat Tuple{Uint64, Uint64}}(), 
                     id2var = Dict{Uint64, Variable}())
  monotonicities = monotonicity(x)
  vex = multicurvature(x, conflicts, id2var)
  for i = 1:length(x.children)
    vex += monotonicities[i] * multivexity(x.children[i], conflicts, id2var)
  end
  return vex
end

function multivexity(x::AbstractExpr)
  conflicts = Set{@compat Tuple{Uint64, Uint64}}()
  id2var = Dict{Uint64, Variable}()
  return multivexity(x, conflicts, id2var), conflicts, id2var
end

# constraints are multiconvex iff they are convex
multivexity(x::Constraint) = vexity(x)

# a problem is multiconvex if there exists a partition of the variables 
# in the problem such that
  # 1. the objective is convex in each element of the partition holding the others constant
  # 2. all constraints are convex
  # 3. all variables participating in any constraint are in the same element of the partition
# this function checks multiconvexity of a problem 
# and returns the partition that certifies multiconvexity
function multivexity(problem::Problem)
  bad_vex = [ConcaveVexity, NotDcp]

  conflicts = Set{@compat Tuple{Uint64, Uint64}}()
  id2var = Dict{Uint64, Variable}()
  obj_vex = multivexity(problem.objective, conflicts, id2var)
  if problem.head == :maximize
    obj_vex = -obj_vex
  end
  # the objective must be convex
  if typeof(obj_vex) in bad_vex
    warn("Expression not DMCP compliant: objective not multiconvex")
  end

  # the constraints must be convex and must not violate the conflicts graph
  m = length(problem.constraints)
  idpartition = Array(Set{Uint64}, m)
  activeparts = fill(true, m)
  for i=1:m
    constraint = problem.constraints[i]
    if typeof(vexity(constraint)) in bad_vex
      warn("Expression not DMCP compliant: constraint $i not multiconvex")
    end
    vars = variablesin(constraint, id2var)
    # if the variables in two constraints intersect, 
    # the the union of their variables must be in the same partition
    for j=(1:i-1)[activeparts[1:i-1]] # for every subset known to be in the partition
      if length(intersect(idpartition[j], vars)) > 0
        union!(vars, idpartition[j])
        activeparts[j] = false
      end
    end
    idpartition[i] = vars
    activeparts[i] = true
  end
  idpartition = idpartition[activeparts]

  # check that the variables that must be simultaneously active don't violate the conflicts graph
  for s in idpartition
    if !isstableset(s, conflicts)
      warn("Expression not DMCP compliant: 
        variables appearing together in a constraint 
        must be in different subsets of the partition 
        to ensure the objective is convex.")
    end
  end

  # ok, now partition the remaining variables 
  # and add them to the appropriate subsets in idpartition
  stablepartition!(conflicts, idpartition)

  # make list of vars and stablesets by Variable rather than by id
  vars = Variable[id2var[id] for id in keys(id2var)]
  stablesetvars = Array{Variable,1}[Variable[id2var[id] for id in s] for s in idpartition]

  return obj_vex, stablesetvars, vars
end