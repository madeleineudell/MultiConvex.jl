# MultiConvex

[![Build Status](https://travis-ci.org/madeleineudell/MultiConvex.jl.svg?branch=master)](https://travis-ci.org/madeleineudell/MultiConvex.jl)

**MultiConvex.jl** is a [Julia](http://julialang.org) package for [disciplined multi-convex programming](https://arxiv.org/abs/1609.03285). MultiConvex.jl can detect and (heuristically) solve multi-convex problems using alternating minimization. It solves the subproblems it encounters using [Convex.jl](https://github.com/JuliaOpt/Convex.jl) and so can use any solver supported by Convex.jl, including [Mosek](https://github.com/JuliaOpt/Mosek.jl), [Gurobi](https://github.com/JuliaOpt/gurobi.jl), [ECOS](https://github.com/JuliaOpt/ECOS.jl), [SCS](https://github.com/JuliaOpt/SCS.jl), [GLPK](https://github.com/JuliaOpt/GLPK.jl), through the [MathProgBase](http://mathprogbasejl.readthedocs.org/en/latest/) interface.

More resources:
* our [paper on disciplined multi-convex programming](https://arxiv.org/abs/1609.03285)
* [slides on disciplined multi-convex programming](doc/multiconvex_slides.pdf)
* a [CVXPY extension for multi-convex programming in Python](https://github.com/cvxgrp/dmcp).

**Installation**:
Clone the MultiConvex repository, and install Convex.
```julia
julia> Pkg.clone("https://github.com/madeleineudell/MultiConvex.jl.git")
julia> Pkg.add("Convex")
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

## Citing this package

If you use MultiConvex.jl for published work, we encourage you to cite the software using the following BibTeX citation:
```
@article{shen2016disciplined,
  title={Disciplined Multi-Convex Programming},
  author={Shen, Xinyue and Diamond, Steven and Udell, Madeleine and Gu, Yuantao and Boyd, Stephen},
  journal={arXiv preprint arXiv:1609.03285},
  year={2016}
}
```
