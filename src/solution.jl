import MathProgBase, Convex.conic_form!, Convex.SolverOrModel, Convex.get_default_solver
import Convex

export altmin!

function altmin!(problem::Problem,
                s::MathProgBase.AbstractMathProgSolver=get_default_solver();
                warmstart=true, maxAMiters=5)

  obj_vex, stablesets, vars = multivexity(problem)

  # initialize
  # TODO
  #   1) make sure initial values are feasible
  for v in vars
    if v.value == nothing || !warmstart
      v.value = rand(size(v))
    end
    fix!(v)
  end

  solved_subproblem = false
  for iter=1:maxAMiters
    for s in stablesets
      # free the variables in s to optimize over just those variables
      for v in s
        free!(v)
      end
      if solved_subproblem
        Convex.solve!(problem, warmstart=true)
      else
        Convex.solve!(problem, warmstart=false)
        solved_subproblem = true
      end
      # now that we've found their values, fix them again
      for v in s
        fix!(v)
      end
    end
  end
  return problem
end
