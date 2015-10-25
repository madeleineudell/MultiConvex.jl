# MultiConvex

[![Build Status](https://travis-ci.org/madeleineudell/MultiConvex.jl.svg?branch=master)](https://travis-ci.org/madeleineudell/MultiConvex.jl)

**MultiConvex.jl** is a [Julia](http://julialang.org) package for [Disciplined Multiconvex Programming](doc/multiconvex_slides.pdf). MultiConvex.jl can detect and (heuristically) solve multiconvex problems using alternating minimization. It solves the subproblems it encounters using [Convex.jl](https://github.com/JuliaOpt/Convex.jl) and so can use any solver supported by Convex.jl, including [Mosek](https://github.com/JuliaOpt/Mosek.jl), [Gurobi](https://github.com/JuliaOpt/gurobi.jl), [ECOS](https://github.com/JuliaOpt/ECOS.jl), [SCS](https://github.com/JuliaOpt/SCS.jl), [GLPK](https://github.com/JuliaOpt/GLPK.jl), through the [MathProgBase](http://mathprogbasejl.readthedocs.org/en/latest/) interface.

**Installation**: 
Clone the MultiConvex and Convex repositories. (Note: MultiConvex does not currently work with the version of Convex tagged in METADATA.)
```julia
julia> Pkg.clone("https://github.com/madeleineudell/MultiConvex.jl.git")
julia> Pkg.clone("https://github.com/madeleineudell/Convex.jl.git")
```

- If you're running into **bugs or have feature requests**, please use the [Github Issue Tracker](https://github.com/madeleineudell/MultiConvex.jl/issues>).
- For usage questions, please contact us via the [JuliaOpt mailing list](https://groups.google.com/forum/#!forum/julia-opt)

## Quick Example

Here's a quick example of code that solves a nonnegative matrix factorization problem
```julia
# Let us first make the Convex and MultiConvex modules available
using Convex, MultiConvex

# initialize nonconvex problem
n, k = 10, 1
A = rand(n, k) * rand(k, n)
x = Variable(n, k)
y = Variable(k, n)
problem = minimize(sum_squares(A - x*y), x>=0, y>=0)

# perform alternating minimization on the problem by calling altmin!
altmin!(problem)

# Check the status of the last subproblem solved
problem.status # :Optimal, :Infeasible, :Unbounded etc.

# Get the objective value
problem.optval
```