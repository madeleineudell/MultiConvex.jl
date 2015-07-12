import MathProgBase, Convex.conic_form!, Convex.SolverOrModel, Convex.get_default_solver
import Convex

export altmin!

function altmin!(problem::Problem,
                s::SolverOrModel=get_default_solver();
                warmstart=true, maxAMiters=5)

  vex, stablesets, id2var = multivexity(problem)

  # initialize
  # TODO 
  #   1) make sure initial values are feasible
  for v in vars
    if v.value == nothing
      v.value = rand(size(v))
    end
    fix!(v)
  end

  for iter=1:maxAMiters
    for s in stablesets
      # free the variables in s to optimize over just those variables
      for v in s
        free!(v)
      end
      Convex.solve!(problem, warmstart=true, )
      # now that we've found their values, fix them again
      for v in s
        fix!(v)
      end     
    end
  end 
  return problem
end