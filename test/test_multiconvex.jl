using Convex, MultiConvex, Compat, SCS
set_default_solver(SCSSolver(verbose=false))
using Base.Test
import Convex.hash

x = Variable()
y = Variable()
z = Variable()
x.value = 1
y.value = 2
z.value = 3

# variables in
@assert length(variablesin(x*y*z)) == 3
@assert length(variablesin(x*y+y*z+x+y+z)) == 3
@assert length(variablesin(log(x) + 7*x + 5)) == 1

# partitioning sets of integers
n = Dict{Int, Set{Int}}({1=>Set{Int}({2,3,4}),
	                             2=>Set{Int}({1,3}),
	                             3=>Set{Int}({1,2}),
	                             4=>Set{Int}({1}),
	                             5=>Set{Int}({6,7}),
	                             6=>Set{Int}({5,7}),
	                             7=>Set{Int}({6,5})})
p = stablepartition!(n)
@assert length(p) == 3
@assert sum(map(length, p)) == 7
@assert length(union(p...)) == 7

# partitioning given initial sets
p = stablepartition!(n, Set{Int}[Set{Int}({1,5})])
@assert length(p) == 3
@assert sum(map(length, p)) == 7
@assert length(union(p...)) == 7
@assert p[1] == Set({1,5})

# multivexity: (convex) addition
conflicts = Set{@compat Tuple{Uint64, Uint64}}()
@assert multivexity(x+y, conflicts) == AffineVexity()
@assert length(conflicts) == 0

# multivexity: (biconvex) multiplication
conflicts = Set{@compat Tuple{Uint64, Uint64}}()
v = multivexity(x*y, conflicts)
@assert v == AffineVexity()
@assert length(conflicts) == 1
@assert pop!(conflicts) == (x.id_hash, y.id_hash) 
# note hash(x::Variable) is not defined to grab id_hash except *internally* in the multiconvex module

# multivexity: addition and multiplication
conflicts = Set{@compat Tuple{Uint64, Uint64}}()
v = multivexity(x*y + y*z + z*x, conflicts)
@assert v == AffineVexity()
@assert length(conflicts) == 3

# partitioning variables given conflict graphs
conflicts = Set{@compat Tuple{Uint64, Uint64}}()
m = x*y + y*z + z*x
v = multivexity(m, conflicts)
vars = variablesin(m)
parts = stablepartition!(conflicts)
@assert length(parts) == 3
@assert all(map(x -> length(x) == 1, parts))

# multivexity: problems with no constraints
x = Variable()
y = Variable()
z = Variable()
problem = minimize(exp(x*y*z) + x^2 + y^2 + z^2)
vex, stablesetvars, vars = multivexity(problem)
@assert length(vars) == 3
@assert length(stablesetvars) == 3
@assert sum(map(length, stablesetvars)) == 3
@assert vex == ConvexVexity()

# multivexity: problems with constraints
x = Variable()
y = Variable()
z = Variable()
w = Variable()
problem = minimize(exp(x*z) + exp(w*y) + x^2 + y^2 + z^2, x+y >= 0)
vex, stablesetvars, vars = multivexity(problem)
@assert length(vars) == 4
@assert length(stablesetvars) == 2
@assert map(length, stablesetvars) == [2, 2]
@assert vex == ConvexVexity()

# solving a simple problem
x = Variable()
y = Variable()
z = Variable()
# solution to this problem should be (0,0,0)
problem = minimize(exp(x*y*z) + x^2 + y^2 + z^2, x>=0, y>=0, z>=0)
altmin!(problem)
@show t1 = (x.value, y.value, z.value)
# solution to this problem should be closer to (some permutation of) (0,1,1)
problem = minimize(exp(x*y*z) + 5*(1-x)^2 + 5*(1-y)^2 + 5*(1-z)^2, x>=0, y>=0, z>=0)
altmin!(problem, warmstart = false, maxAMiters=100)
@show t2 = (x.value[1], y.value[1], z.value[1])
@assert sort([t2...])[2] > maximum(t1)