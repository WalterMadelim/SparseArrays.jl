# This file is a part of Julia. License is MIT: https://julialang.org/license

module CHOLMODTests
using Test

@static if !Base.USE_GPL_LIBS
    @info "This Julia build excludes the use of SuiteSparse GPL libraries. Skipping CHOLMOD tests"
else

using SparseArrays.CHOLMOD
using SparseArrays.CHOLMOD: getcommon
using Random
using Serialization
using LinearAlgebra:
    I, cholesky, cholesky!, det, diag, eigmax, ishermitian, isposdef, issuccess,
    issymmetric, ldiv!, ldlt, ldlt!, logdet, norm, opnorm, Diagonal, Hermitian, Symmetric,
    PosDefException, ZeroPivotException, RowMaximum
using SparseArrays
using SparseArrays: getcolptr
using SparseArrays.LibSuiteSparse
using SparseArrays.LibSuiteSparse: cholmod_l_allocate_sparse, cholmod_allocate_sparse

# CHOLMOD tests
itypes = sizeof(Int) == 4 ? (Int32,) : (Int32, Int64)
for Ti ∈ itypes, Tv ∈ (Float32, Float64)
Random.seed!(123)

@testset "based on deps/SuiteSparse-4.0.2/CHOLMOD/Demo/ index type $Ti" begin

# chm_rdsp(joinpath(Sys.BINDIR, "../../deps/SuiteSparse-4.0.2/CHOLMOD/Demo/Matrix/bcsstk01.tri"))
# because the file may not exist in binary distributions and when a system suitesparse library
# is used

## Result from C program
## ---------------------------------- cholmod_demo:
## norm (A,inf) = 3.57095e+09
## norm (A,1)   = 3.57095e+09
## CHOLMOD sparse:  A:  48-by-48, nz 224, upper.  OK
## CHOLMOD dense:   B:  48-by-1,   OK
## bnorm 1.97917
## Analyze: flop 6009 lnz 489
## Factorizing A
## CHOLMOD factor:  L:  48-by-48  simplicial, LDL'. nzmax 489.  nz 489  OK
## Ordering: AMD     fl/lnz       12.3  lnz/anz        2.2
## ints in L: 782, doubles in L: 489
## factor flops 6009 nnz(L)             489 (w/no amalgamation)
## nnz(A*A'):             224
## flops / nnz(L):      12.3
## nnz(L) / nnz(A):      2.2
## analyze cputime:        0.0000
## factor  cputime:         0.0000 mflop:      0.0
## solve   cputime:         0.0000 mflop:      0.0
## overall cputime:         0.0000 mflop:      0.0
## peak memory usage:            0 (MB)
## residual  2.5e-19 (|Ax-b|/(|A||x|+|b|))
## residual  1.3e-19 (|Ax-b|/(|A||x|+|b|)) after iterative refinement
## rcond     9.5e-06

    n = 48
    A = CHOLMOD.Sparse(n, n,
        Ti[0,1,2,3,6,9,12,15,18,20,25,30,34,36,39,43,47,52,58,
        62,67,71,77,84,90,93,95,98,103,106,110,115,119,123,130,136,142,146,150,155,
        161,167,174,182,189,197,207,215,224], # zero-based column pointers
        Ti[0,1,2,1,2,3,0,2,4,0,1,5,0,4,6,1,3,7,2,8,1,3,7,8,9,
        0,4,6,8,10,5,6,7,11,6,12,7,11,13,8,10,13,14,9,13,14,15,8,10,12,14,16,7,11,
        12,13,16,17,0,12,16,18,1,5,13,15,19,2,4,14,20,3,13,15,19,20,21,2,4,12,16,18,
        20,22,1,5,17,18,19,23,0,5,24,1,25,2,3,26,2,3,25,26,27,4,24,28,0,5,24,29,6,
        11,24,28,30,7,25,27,31,8,9,26,32,8,9,25,27,31,32,33,10,24,28,30,32,34,6,11,
        29,30,31,35,12,17,30,36,13,31,35,37,14,15,32,34,38,14,15,33,37,38,39,16,32,
        34,36,38,40,12,17,31,35,36,37,41,12,16,17,18,23,36,40,42,13,14,15,19,37,39,
        43,13,14,15,20,21,38,43,44,13,14,15,20,21,37,39,43,44,45,12,16,17,22,36,40,
        42,46,12,16,17,18,23,41,42,46,47],
        Tv[2.83226851852e6,1.63544753086e6,1.72436728395e6,-2.0e6,-2.08333333333e6,
        1.00333333333e9,1.0e6,-2.77777777778e6,1.0675e9,2.08333333333e6,
        5.55555555555e6,1.53533333333e9,-3333.33333333,-1.0e6,2.83226851852e6,
        -6666.66666667,2.0e6,1.63544753086e6,-1.68e6,1.72436728395e6,-2.0e6,4.0e8,
        2.0e6,-2.08333333333e6,1.00333333333e9,1.0e6,2.0e8,-1.0e6,-2.77777777778e6,
        1.0675e9,-2.0e6,2.08333333333e6,5.55555555555e6,1.53533333333e9,-2.8e6,
        2.8360994695e6,-30864.1975309,-5.55555555555e6,1.76741074446e6,
        -15432.0987654,2.77777777778e6,517922.131816,3.89003806848e6,
        -3.33333333333e6,4.29857058902e6,-2.6349902747e6,1.97572063531e9,
        -2.77777777778e6,3.33333333333e8,-2.14928529451e6,2.77777777778e6,
        1.52734651547e9,5.55555555555e6,6.66666666667e8,2.35916180402e6,
        -5.55555555555e6,-1.09779731332e8,1.56411143711e9,-2.8e6,-3333.33333333,
        1.0e6,2.83226851852e6,-30864.1975309,-5.55555555555e6,-6666.66666667,
        -2.0e6,1.63544753086e6,-15432.0987654,2.77777777778e6,-1.68e6,
        1.72436728395e6,-3.33333333333e6,2.0e6,4.0e8,-2.0e6,-2.08333333333e6,
        1.00333333333e9,-2.77777777778e6,3.33333333333e8,-1.0e6,2.0e8,1.0e6,
        2.77777777778e6,1.0675e9,5.55555555555e6,6.66666666667e8,-2.0e6,
        2.08333333333e6,-5.55555555555e6,1.53533333333e9,-28935.1851852,
        -2.08333333333e6,60879.6296296,-1.59791666667e6,3.37291666667e6,
        -28935.1851852,2.08333333333e6,2.41171296296e6,-2.08333333333e6,
        1.0e8,-2.5e6,-416666.666667,1.5e9,-833333.333333,1.25e6,5.01833333333e8,
        2.08333333333e6,1.0e8,416666.666667,5.025e8,-28935.1851852,
        -2.08333333333e6,-4166.66666667,-1.25e6,3.98587962963e6,-1.59791666667e6,
        -8333.33333333,2.5e6,3.41149691358e6,-28935.1851852,2.08333333333e6,
        -2.355e6,2.43100308642e6,-2.08333333333e6,1.0e8,-2.5e6,5.0e8,2.5e6,
        -416666.666667,1.50416666667e9,-833333.333333,1.25e6,2.5e8,-1.25e6,
        -3.47222222222e6,1.33516666667e9,2.08333333333e6,1.0e8,-2.5e6,
        416666.666667,6.94444444444e6,2.16916666667e9,-28935.1851852,
        -2.08333333333e6,-3.925e6,3.98587962963e6,-1.59791666667e6,
        -38580.2469136,-6.94444444444e6,3.41149691358e6,-28935.1851852,
        2.08333333333e6,-19290.1234568,3.47222222222e6,2.43100308642e6,
        -2.08333333333e6,1.0e8,-4.16666666667e6,2.5e6,-416666.666667,
        1.50416666667e9,-833333.333333,-3.47222222222e6,4.16666666667e8,
        -1.25e6,3.47222222222e6,1.33516666667e9,2.08333333333e6,1.0e8,
        6.94444444445e6,8.33333333333e8,416666.666667,-6.94444444445e6,
        2.16916666667e9,-3830.95098171,1.14928529451e6,-275828.470683,
        -28935.1851852,-2.08333333333e6,-4166.66666667,1.25e6,64710.5806113,
        -131963.213599,-517922.131816,-2.29857058902e6,-1.59791666667e6,
        -8333.33333333,-2.5e6,3.50487988027e6,-517922.131816,-2.16567078453e6,
        551656.941366,-28935.1851852,2.08333333333e6,-2.355e6,517922.131816,
        4.57738374749e6,2.29857058902e6,-551656.941367,4.8619365099e8,
        -2.08333333333e6,1.0e8,2.5e6,5.0e8,-4.79857058902e6,134990.2747,
        2.47238730198e9,-1.14928529451e6,2.29724661236e8,-5.57173510779e7,
        -833333.333333,-1.25e6,2.5e8,2.39928529451e6,9.61679848804e8,275828.470683,
        -5.57173510779e7,1.09411960038e7,2.08333333333e6,1.0e8,-2.5e6,
        140838.195984,-1.09779731332e8,5.31278103775e8], 1)
    @test CHOLMOD.norm_sparse(A, 0) ≈ 3.570948074697437e9
    @test CHOLMOD.norm_sparse(A, 1) ≈ 3.570948074697437e9
    @test_throws ArgumentError CHOLMOD.norm_sparse(A, 2)
    @test CHOLMOD.isvalid(A)

    x = fill(Tv(1.), n)
    b = A*x

    chma = ldlt(A)                      # LDL' form
    @test CHOLMOD.isvalid(chma)
    @test unsafe_load(pointer(chma)).is_ll == 0    # check that it is in fact an LDLt
    @test chma\b ≈ x
    @test nnz(ldlt(A, perm=1:size(A,1))) > nnz(chma)
    @test size(chma) == size(A)
    chmal = CHOLMOD.FactorComponent(chma, :L)
    @test size(chmal) == size(A)
    @test size(chmal, 1) == size(A, 1)

    chma = cholesky(A)                      # LL' form
    @test CHOLMOD.isvalid(chma)
    @test unsafe_load(pointer(chma)).is_ll == 1    # check that it is in fact an LLt
    @test chma\b ≈ x
    x2 = zero(x)
    @inferred ldiv!(x2, chma, b)
    @test x2 ≈ x
    @test nnz(chma) == 489
    @test nnz(cholesky(A, perm=1:size(A,1))) > nnz(chma)
    @test size(chma) == size(A)
    chmal = CHOLMOD.FactorComponent(chma, :L)
    @test size(chmal) == size(A)
    @test size(chmal, 1) == size(A, 1)

    @testset "eltype" begin
        @test eltype(Dense(fill(Tv(1.), 3))) == Tv
        @test eltype(A) == Tv
        @test eltype(chma) == Tv
    end
end


for Tv2 ∈ (Float32, Float64)
@testset "lp_afiro example ($Tv, $Ti) \\ ($Tv2, $Ti)" begin
    afiro = CHOLMOD.Sparse(27, 51,
        Ti[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,
        23,25,27,29,33,37,41,45,47,49,51,53,55,57,59,63,65,67,69,71,75,79,83,87,89,
        91,93,95,97,99,101,102],
        Ti[2,3,6,7,8,9,12,13,16,17,18,19,20,21,22,23,24,25,26,
        0,1,2,23,0,3,0,21,1,25,4,5,6,24,4,5,7,24,4,5,8,24,4,5,9,24,6,20,7,20,8,20,9,
        20,3,4,4,22,5,26,10,11,12,21,10,13,10,23,10,20,11,25,14,15,16,22,14,15,17,
        22,14,15,18,22,14,15,19,22,16,20,17,20,18,20,19,20,13,15,15,24,14,26,15],
        Tv[1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,
        1.0,-1.0,-1.06,1.0,0.301,1.0,-1.0,1.0,-1.0,1.0,1.0,-1.0,-1.06,1.0,0.301,
        -1.0,-1.06,1.0,0.313,-1.0,-0.96,1.0,0.313,-1.0,-0.86,1.0,0.326,-1.0,2.364,
        -1.0,2.386,-1.0,2.408,-1.0,2.429,1.4,1.0,1.0,-1.0,1.0,1.0,-1.0,-0.43,1.0,
        0.109,1.0,-1.0,1.0,-1.0,1.0,-1.0,1.0,1.0,-0.43,1.0,1.0,0.109,-0.43,1.0,1.0,
        0.108,-0.39,1.0,1.0,0.108,-0.37,1.0,1.0,0.107,-1.0,2.191,-1.0,2.219,-1.0,
        2.249,-1.0,2.279,1.4,-1.0,1.0,-1.0,1.0,1.0,1.0], 0)
    afiro2 = CHOLMOD.aat(afiro, Ti[0:50;], Ti(1))
    CHOLMOD.change_stype!(afiro2, -1)
    chmaf = cholesky(afiro2)
    y = afiro'*fill(one(Tv), size(afiro,1))
    sol = @test_nowarn chmaf\convert(Dense{Tv2}, (afiro*y)) # least squares solution
    @test eltype(sol) == promote_type(Tv, Tv2)
    @test CHOLMOD.isvalid(sol)
    pred = afiro'*sol
    @test norm(afiro * (convert(Matrix, y) - convert(Matrix, pred))) <
        √(eps(Float32 <: Union{Tv, Tv2} ? Float32 : Float64)) # is this reasonable?
end
end

@testset "Issue 9160 $Ti" begin
    local A, B
    A = sprand(10, 10, 0.1)
    A = convert(SparseMatrixCSC{Tv,Ti}, A)
    cmA = CHOLMOD.Sparse(A)

    B = sprand(10, 10, 0.1)
    B = convert(SparseMatrixCSC{Tv,Ti}, B)
    cmB = CHOLMOD.Sparse(B)

    # Ac_mul_B
    @test sparse(cmA'*cmB) ≈ A'*B

    # A_mul_Bc
    @test sparse(cmA*cmB') ≈ A*B'

    # A_mul_Ac
    @test sparse(cmA*cmA') ≈ A*A'

    # Ac_mul_A
    @test sparse(cmA'*cmA) ≈ A'*A

    # A_mul_Ac for symmetric A
    A = 0.5*(A + copy(A'))
    cmA = CHOLMOD.Sparse(A)
    @test sparse(cmA*cmA') ≈ A*A'
end

@testset "Check inputs to Sparse. Related to #20024" for t_ in (
    (2, 2, [1, 2], Ti[], Tv[]),
    (2, 2, [1, 2, 3], Ti[1], Tv[]),
    (2, 2, [1, 2, 3], Ti[], Tv[1.0]),
    (2, 2, [1, 2, 3], Ti[1], Tv[1.0]))
    @test_throws ArgumentError SparseMatrixCSC(t_...)
    @test_throws ArgumentError CHOLMOD.Sparse(t_[1], t_[2], t_[3] .- 1, t_[4] .- 1, t_[5])
end

## The struct pointer must be constructed by the library constructor and then modified afterwards to checks that the method throws
@testset "illegal dtype" begin
    p = Ti == Int64 ? cholmod_l_allocate_sparse(1, 1, 1, true, true, 0, CHOLMOD.xdtyp(Tv), getcommon(Ti)) :
        cholmod_allocate_sparse(1, 1, 1, true, true, 0, CHOLMOD.xdtyp(Tv), getcommon(Ti))
    puint = convert(Ptr{UInt32}, p)
    # The second argument 5 is the invalid `dtype`.
    # CHOLMOD_DOUBLE (0) and CHOLMOD_SINGLE (4) are both valid.
    unsafe_store!(puint, 5, 3*div(sizeof(Csize_t), 4) + 5*div(sizeof(Ptr{Cvoid}), 4) + 4)
    @test_throws CHOLMOD.CHOLMODException CHOLMOD.Sparse(p)
end

@testset "illegal xtype" begin
    p = Ti == Int64 ? cholmod_l_allocate_sparse(1, 1, 1, true, true, 0, CHOLMOD.xdtyp(Tv), getcommon(Ti)) :
        cholmod_allocate_sparse(1, 1, 1, true, true, 0, CHOLMOD.xdtyp(Tv), getcommon(Ti))
    puint = convert(Ptr{UInt32}, p)
    # The second argument 3 is the invalid `xtype`.
    # CHOLMOD_REAL (1), CHOLMOD_COMPLEX (2) are valid.
    unsafe_store!(puint, 3, 3*div(sizeof(Csize_t), 4) + 5*div(sizeof(Ptr{Cvoid}), 4) + 3)
    @test_throws CHOLMOD.CHOLMODException CHOLMOD.Sparse(p)
end

# Test that a bogus `itype` raises the expected exception
@testset "illegal itype I" begin
    p = Ti == Int64 ? cholmod_l_allocate_sparse(1, 1, 1, true, true, 0, CHOLMOD.xdtyp(Tv), getcommon(Ti)) :
        cholmod_allocate_sparse(1, 1, 1, true, true, 0, CHOLMOD.xdtyp(Tv), getcommon(Ti))
    puint = convert(Ptr{UInt32}, p)
    # The second argument to `unsafe_store!` is the illegal `itype`
    unsafe_store!(puint, 123, 3*div(sizeof(Csize_t), 4) + 5*div(sizeof(Ptr{Cvoid}), 4) + 2)
    @test_throws CHOLMOD.CHOLMODException CHOLMOD.Sparse(p)
end

@testset "illegal itype II" begin
    p = Ti == Int64 ? cholmod_l_allocate_sparse(1, 1, 1, true, true, 0, CHOLMOD.xdtyp(Tv), getcommon(Ti)) :
        cholmod_allocate_sparse(1, 1, 1, true, true, 0, CHOLMOD.xdtyp(Tv), getcommon(Ti))
    puint = convert(Ptr{UInt32}, p)
    unsafe_store!(puint,  5, 3*div(sizeof(Csize_t), 4) + 5*div(sizeof(Ptr{Cvoid}), 4) + 2)
    @test_throws CHOLMOD.CHOLMODException CHOLMOD.Sparse(p)
end
@testset "test free! $Ti" begin
    p = Ti == Int64 ? cholmod_l_allocate_sparse(1, 1, 1, true, true, 0, CHOLMOD.xdtyp(Tv), getcommon(Ti)) :
        cholmod_allocate_sparse(1, 1, 1, true, true, 0, CHOLMOD.xdtyp(Tv), getcommon(Ti))
    @test CHOLMOD.free!(p, Ti)
end

@testset "Check common is still in default state" begin
    # This test intentionally depends on all the above tests!
    current_common = CHOLMOD.getcommon(Ti)
    default_common = Ref(cholmod_common())
    result = Ti === Int64 ? cholmod_l_start(default_common) : cholmod_start(default_common)
    @test result == CHOLMOD.TRUE
    @test current_common[].print == 0
    for name in (
        :nmethods,
        :postorder,
        :final_ll,
        :supernodal,
    )
        @test getproperty(current_common[], name) == getproperty(default_common[], name)
    end
end

@testset "ldiv! $Tv $Ti" begin
    local A, x, x2, b, X, X2, B
    A = sprand(10, 10, 0.1)
    A = I + A * A'
    A = convert(SparseMatrixCSC{Tv,Ti}, A)
    factor = cholesky(A)

    x = fill(Tv(1), 10)
    b = A * x
    x2 = zero(x)
    @inferred ldiv!(x2, factor, b)
    @test x2 ≈ x

    X = fill(Tv(1), 10, 5)
    B = A * X
    X2 = zero(X)
    @inferred ldiv!(X2, factor, B)
    @test X2 ≈ X

    c = fill(Tv(1), size(x, 1) + 1)
    C = fill(Tv(1), size(X, 1) + 1, size(X, 2))
    y = fill(Tv(1), size(x, 1) + 1)
    Y = fill(Tv(1), size(X, 1) + 1, size(X, 2))
    @test_throws DimensionMismatch ldiv!(y, factor, b)
    @test_throws DimensionMismatch ldiv!(Y, factor, B)
    @test_throws DimensionMismatch ldiv!(x2, factor, c)
    @test_throws DimensionMismatch ldiv!(X2, factor, C)
    @test_throws DimensionMismatch ldiv!(X2, factor, b)
    @test_throws DimensionMismatch ldiv!(x2, factor, B)
end

end #end for Ti ∈ itypes

for Tv ∈ (Float32, Float64)
@testset "Issue #9915" begin
    sparseI = sparse(Tv(1.0)I, 2, 2)
    @test sparseI \ sparseI == sparseI
end

@testset "test Sparse constructor Symmetric and Hermitian input (and issymmetric and ishermitian)" begin
    ACSC = sprandn(Tv, 10, 10, 0.3) + I
    @test issymmetric(Sparse(Symmetric(ACSC, :L)))
    @test issymmetric(Sparse(Symmetric(ACSC, :U)))
    @test ishermitian(Sparse(Hermitian(complex(ACSC), :L)))
    @test ishermitian(Sparse(Hermitian(complex(ACSC), :U)))
end

@testset "test Sparse constructor and read_sparse" begin
    # avoid dependenting on delimited files
    function writedlm(fn, title="", xs...)
        open(fn, "w") do file
            println(file, title)
            for i in xs
                println(file, i)
            end
        end
    end
    mktempdir() do temp_dir
        testfile = joinpath(temp_dir, "tmp.mtx")

        writedlm(testfile, "%%MatrixMarket matrix coordinate real symmetric","3 3 4","1 1 1","2 2 1","3 2 0.5","3 3 1")
        @test sparse(CHOLMOD.Sparse(testfile)) == [1 0 0;0 1 0.5;0 0.5 1]
        rm(testfile)

        writedlm(testfile, "%%MatrixMarket matrix coordinate complex Hermitian",
                        "3 3 4","1 1 1.0 0.0","2 2 1.0 0.0","3 2 0.5 0.5","3 3 1.0 0.0")
        @test sparse(CHOLMOD.Sparse(testfile)) == [1 0 0;0 1 0.5-0.5im;0 0.5+0.5im 1]
        rm(testfile)

        # this also tests that the error message is correctly retrieved from the library
        writedlm(testfile, "%%MatrixMarket matrix coordinate real symmetric","%3 3 4","1 1 1","2 2 1","3 2 0.5","3 3 1")
        @test_throws CHOLMOD.CHOLMODException("indices out of range") sparse(CHOLMOD.Sparse(testfile))
        rm(testfile)
    end
end

@testset "High level interface" for elty in (Tv, Complex{Tv})
    local A, b
    if elty <: Real
        A = randn(Tv, 5, 5)
        b = randn(Tv, 5)
    else
        A = complex.(randn(Tv, 5, 5), randn(Tv, 5, 5))
        b = complex.(randn(Tv, 5), randn(Tv, 5))
    end
    ADense = CHOLMOD.Dense(A)
    bDense = CHOLMOD.Dense(b)

    @test_throws BoundsError ADense[6, 1]
    @test_throws BoundsError ADense[1, 6]
    @test copy(ADense) == ADense
    @test CHOLMOD.norm_dense(ADense, 1) ≈ opnorm(A, 1)
    @test CHOLMOD.norm_dense(ADense, 0) ≈ opnorm(A, Inf)
    @test_throws ArgumentError CHOLMOD.norm_dense(ADense, 2)
    @test_throws ArgumentError CHOLMOD.norm_dense(ADense, 3)

    @test CHOLMOD.norm_dense(bDense, 2) ≈ norm(b)
    @test CHOLMOD.check_dense(bDense)

    AA = CHOLMOD.eye(3, Tv)
    unsafe_store!(convert(Ptr{Csize_t}, pointer(AA)), 2, 1) # change size, but not stride, of Dense
    @test convert(Matrix, AA) == Matrix(I, 2, 3)
end

@testset "Low level interface" begin
    @test isa(CHOLMOD.zeros(3, 3, Tv), CHOLMOD.Dense{Tv})
    @test isa(CHOLMOD.zeros(3, 3), CHOLMOD.Dense{Float64})
    @test isa(CHOLMOD.ones(3, 3, Tv), CHOLMOD.Dense{Tv})
    @test isa(CHOLMOD.ones(3, 3), CHOLMOD.Dense{Float64})
    @test isa(CHOLMOD.eye(3, 4, Tv), CHOLMOD.Dense{Tv})
    @test isa(CHOLMOD.eye(3, 4), CHOLMOD.Dense{Float64})
    @test isa(CHOLMOD.eye(3, Tv), CHOLMOD.Dense{Tv})
    @test isa(CHOLMOD.eye(3), CHOLMOD.Dense{Float64})
end

@testset "Core functionality ($elty, $elty2)" for
    elty in (Tv, Complex{Tv}),
    Tv2 in (Float32, Float64),
    elty2 in (Tv2, Complex{Tv2}),
    Ti ∈ itypes
    A1 = sparse(Ti[1:5; 1], Ti[1:5; 2], elty <: Real ? randn(Tv, 6) : complex.(randn(Tv, 6), randn(Tv, 6)))
    A2 = sparse(Ti[1:5; 1], Ti[1:5; 2], elty2 <: Real ? randn(Tv2, 6) : complex.(randn(Tv2, 6), randn(Tv2, 6)))
    A1pd = A1'A1 + 10I
    A1pdSparse = CHOLMOD.Sparse(
        size(A1pd, 1),
        size(A1pd, 2),
        SparseArrays.decrement(getcolptr(A1pd)),
        SparseArrays.decrement(rowvals(A1pd)),
        nonzeros(A1pd))

    ## High level interface
    @test isa(CHOLMOD.Sparse(3, 3, Ti[0,1,3,4], Ti[0,2,1,2], fill(one(Tv), 4)), CHOLMOD.Sparse) # Sparse doesn't require columns to be sorted
    for i ∈ axes(A1, 1)
        A1[i, i] = real(A1[i, i])
    end #Construct Hermitian matrix properly
    A1Sparse = CHOLMOD.Sparse(A1)
    A2Sparse = CHOLMOD.Sparse(A2)
    @test_throws BoundsError A1Sparse[6, 1]
    @test_throws BoundsError A1Sparse[1, 6]
    @test sparse(A1Sparse) == A1
    @test CHOLMOD.sparse(CHOLMOD.Sparse(Hermitian(A1, :L))) == Hermitian(A1, :L)
    @test CHOLMOD.sparse(CHOLMOD.Sparse(Hermitian(A1, :U))) == Hermitian(A1, :U)
    @test_throws ArgumentError convert(SparseMatrixCSC{elty,Ti}, A1pdSparse)
    if elty <: Real
        @test_throws ArgumentError convert(Symmetric{Tv,SparseMatrixCSC{Tv,Ti}}, A1Sparse)
    else
        @test_throws ArgumentError convert(Hermitian{Complex{Tv},SparseMatrixCSC{Complex{Tv},Ti}}, A1Sparse)
    end
    @test copy(A1Sparse) == A1Sparse
    @test size(A1Sparse, 3) == 1
    if elty <: Real # multiplication only defined for real matrices in CHOLMOD
        @test A1Sparse*A2Sparse ≈ A1*A2
        @test_throws DimensionMismatch CHOLMOD.Sparse(A1[:,1:4])*A2Sparse
        @test A1Sparse'A2Sparse ≈ A1'A2
        @test A1Sparse*A2Sparse' ≈ A1*A2'

        @test A1Sparse*A1Sparse ≈ A1*A1
        @test A1Sparse'A1Sparse ≈ A1'A1
        @test A1Sparse*A1Sparse' ≈ A1*A1'

        @test A1pdSparse*A1pdSparse ≈ A1pd*A1pd
        @test A1pdSparse'A1pdSparse ≈ A1pd'A1pd
        @test A1pdSparse*A1pdSparse' ≈ A1pd*A1pd'

        @test_throws DimensionMismatch A1Sparse*CHOLMOD.eye(4, 5, elty)
    end

    # Factor
    @test_throws ArgumentError cholesky(A1)
    @test_throws ArgumentError cholesky(A1)
    @test_throws ArgumentError cholesky(A1, shift=1.0)
    @test_throws ArgumentError ldlt(A1)
    @test_throws ArgumentError ldlt(A1, shift=1.0)
    C = A1 + copy(adjoint(A1))
    λmaxC = eigmax(Array(C))
    b = fill(one(Tv), size(A1, 1))
    @test_throws PosDefException cholesky(C - 2λmaxC*I)
    @test_throws PosDefException cholesky(C, shift=-2λmaxC)
    @test_throws ZeroPivotException ldlt(C - C[1,1]*I)
    @test_throws ZeroPivotException ldlt(C, shift=-real(C[1,1]))
    @test !isposdef(cholesky(C - 2λmaxC*I; check = false))
    @test !isposdef(cholesky(C, shift=-2λmaxC; check = false))
    @test !issuccess(ldlt(C - C[1,1]*I; check = false))
    @test !issuccess(ldlt(C, shift=-real(C[1,1]); check = false))
    F = cholesky(A1pd)
    tmp = IOBuffer()
    show(tmp, F)
    @test tmp.size > 0
    @test isa(CHOLMOD.Sparse(F), CHOLMOD.Sparse{elty})
    @test_throws DimensionMismatch F\CHOLMOD.Dense(fill(elty(1), 4))
    @test_throws DimensionMismatch F\CHOLMOD.Sparse(sparse(fill(elty(1), 4)))
    b = ones(elty2, 5)
    bT = ones(elty, 5)
    @test F'\bT ≈ Array(A1pd)'\b
    @test F'\sparse(bT) ≈ Array(A1pd)'\b
    @test transpose(F)\bT ≈ conj(A1pd)'\bT
    @test F\CHOLMOD.Sparse(sparse(bT)) ≈ A1pd\b
    @test logdet(F) ≈ logdet(Array(A1pd))
    @test det(F) == exp(logdet(F))
    let # to test supernodal, we must use a larger matrix
        Ftmp = SparseMatrixCSC{Tv, Ti}(sprandn(Tv, 100, 100, 0.1))
        Ftmp = Ftmp'Ftmp + 10I
        @test logdet(cholesky(Ftmp)) ≈ logdet(Array(Ftmp))
    end
    @test logdet(ldlt(A1pd)) ≈ logdet(Array(A1pd))
    @test isposdef(A1pd)
    @test !isposdef(A1)
    @test !isposdef(A1 + copy(A1') |> t -> t - 2eigmax(Array(t))*I)

    if elty <: Real
        @test CHOLMOD.issymmetric(Sparse(A1pd, 0))
        @test CHOLMOD.Sparse(cholesky(Symmetric(A1pd, :L))) == CHOLMOD.Sparse(cholesky(A1pd))
        F1 = CHOLMOD.Sparse(cholesky(Symmetric(A1pd, :L), shift=2))
        F2 = CHOLMOD.Sparse(cholesky(A1pd, shift=2))
        @test F1 == F2
        @test CHOLMOD.Sparse(ldlt(Symmetric(A1pd, :L))) == CHOLMOD.Sparse(ldlt(A1pd))
        F1 = CHOLMOD.Sparse(ldlt(Symmetric(A1pd, :L), shift=2))
        F2 = CHOLMOD.Sparse(ldlt(A1pd, shift=2))
        @test F1 == F2
    else
        @test !CHOLMOD.issymmetric(Sparse(A1pd, 0))
        @test CHOLMOD.ishermitian(Sparse(A1pd, 0))
        @test CHOLMOD.Sparse(cholesky(Hermitian(A1pd, :L))) == CHOLMOD.Sparse(cholesky(A1pd))
        F1 = CHOLMOD.Sparse(cholesky(Hermitian(A1pd, :L), shift=2))
        F2 = CHOLMOD.Sparse(cholesky(A1pd, shift=2))
        @test F1 == F2
        @test CHOLMOD.Sparse(ldlt(Hermitian(A1pd, :L))) == CHOLMOD.Sparse(ldlt(A1pd))
        F1 = CHOLMOD.Sparse(ldlt(Hermitian(A1pd, :L), shift=2))
        F2 = CHOLMOD.Sparse(ldlt(A1pd, shift=2))
        @test F1 == F2
    end

    ### cholesky!/ldlt!
    F = cholesky(A1pd)
    CHOLMOD.change_factor!(F, false, false, true, true)
    @test unsafe_load(pointer(F)).is_ll == 0
    CHOLMOD.change_factor!(F, true, false, true, true)
    @test CHOLMOD.Sparse(cholesky!(copy(F), A1pd)) ≈ CHOLMOD.Sparse(F) # surprisingly, this can cause small ulp size changes so we cannot test exact equality
    @test size(F, 2) == 5
    @test size(F, 3) == 1
    @test_throws ArgumentError size(F, 0)

    F = cholesky(A1pdSparse, shift=2)
    @test isa(CHOLMOD.Sparse(F), CHOLMOD.Sparse{elty, Ti})
    @test CHOLMOD.Sparse(cholesky!(copy(F), A1pd, shift=2.0)) ≈ CHOLMOD.Sparse(F) # surprisingly, this can cause small ulp size changes so we cannot test exact equality

    F = ldlt(A1pd)
    @test isa(CHOLMOD.Sparse(F), CHOLMOD.Sparse{elty, Ti})
    @test CHOLMOD.Sparse(ldlt!(copy(F), A1pd)) ≈ CHOLMOD.Sparse(F) # surprisingly, this can cause small ulp size changes so we cannot test exact equality

    F = ldlt(A1pdSparse, shift=2)
    @test isa(CHOLMOD.Sparse(F), CHOLMOD.Sparse{elty, Ti})
    @test CHOLMOD.Sparse(ldlt!(copy(F), A1pd, shift=2.0)) ≈ CHOLMOD.Sparse(F) # surprisingly, this can cause small ulp size changes so we cannot test exact equality

    @test isa(CHOLMOD.factor_to_sparse!(F), CHOLMOD.Sparse)
    @test_throws CHOLMOD.CHOLMODException CHOLMOD.factor_to_sparse!(F)

    ## Low level interface
    @test CHOLMOD.nnz(A1Sparse) == nnz(A1)
    @test CHOLMOD.speye(5, 5, elty) == Matrix(I, 5, 5)
    @test CHOLMOD.spzeros(5, 5, 5, elty) == zeros(elty, 5, 5)
    if elty <: Real && elty2 <: Real
        @test CHOLMOD.copy(A1Sparse, 0, 1) == A1Sparse
        @test CHOLMOD.horzcat(A1Sparse, A2Sparse, true) == [A1 A2]
        @test CHOLMOD.vertcat(A1Sparse, A2Sparse, true) == [A1; A2]
        svec = fill(one(elty2), 1)
        @test CHOLMOD.scale!(CHOLMOD.Dense(svec), CHOLMOD_SCALAR, A1Sparse) == A1Sparse
        svec = fill(one(elty2), 5)
        @test_throws DimensionMismatch CHOLMOD.scale!(CHOLMOD.Dense(svec), CHOLMOD_SCALAR, A1Sparse)
        @test CHOLMOD.scale!(CHOLMOD.Dense(svec), CHOLMOD_ROW, A1Sparse) == A1Sparse
        @test_throws DimensionMismatch CHOLMOD.scale!(CHOLMOD.Dense([svec; 1]), CHOLMOD_ROW, A1Sparse)
        @test CHOLMOD.scale!(CHOLMOD.Dense(svec), CHOLMOD_COL, A1Sparse) == A1Sparse
        @test_throws DimensionMismatch CHOLMOD.scale!(CHOLMOD.Dense([svec; 1]), CHOLMOD_COL, A1Sparse)
        @test CHOLMOD.scale!(CHOLMOD.Dense(svec), CHOLMOD_SYM, A1Sparse) == A1Sparse
        @test_throws DimensionMismatch CHOLMOD.scale!(CHOLMOD.Dense([svec; 1]), CHOLMOD_SYM, A1Sparse)
        @test_throws DimensionMismatch CHOLMOD.scale!(CHOLMOD.Dense(svec), CHOLMOD_SYM, CHOLMOD.Sparse(A1[:,1:4]))
        @test CHOLMOD.aat(A1Sparse, [0:size(A1,2)-1;], 1) ≈ A1*A1'
        @test CHOLMOD.aat(A1Sparse, [0:1;], 1) ≈ A1[:,1:2]*A1[:,1:2]'
        @test CHOLMOD.copy(A1Sparse, 0, 1) == A1Sparse
    else
        # These operations are not well-supportd for Complex, as CHOLMOD assumes input is Hermitian.
        @test_throws MethodError CHOLMOD.horzcat(A1Sparse, A2Sparse, true) == [A1 A2]
        @test_throws MethodError CHOLMOD.vertcat(A1Sparse, A2Sparse, true) == [A1; A2]
    end
    @test CHOLMOD.ssmult(A1Sparse, A2Sparse, 0, true, true) ≈ A1*A2
    d = fill(one(elty2), 5)
    @test A1Sparse*d ≈ A1*d
    @test A1Sparse'*d ≈ A1'*d
    @test A2Sparse*A2Sparse' ≈ A2*A2'

    @test CHOLMOD.Sparse(CHOLMOD.Dense(A1Sparse)) == A1Sparse
end

@testset "extract factors" begin
    Af = Tv.([4 12 -16; 12 37 -43; -16 -43 98])
    As = sparse(Af)
    Lf = Tv.([2 0 0; 6 1 0; -8 5 3])
    LDf = Tv.([4 0 0; 3 1 0; -4 5 9])  # D is stored along the diagonal
    L_f = Tv.([1 0 0; 3 1 0; -4 5 1])  # L by itself in LDLt of Af
    D_f = Tv.([4 0 0; 0 1 0; 0 0 9])
    p = [2,3,1]
    p_inv = [3,1,2]

    @testset "cholesky, no permutation $Tv" begin
        Fs = cholesky(As, perm=[1:3;])
        @test Fs.p == [1:3;]
        @test sparse(Fs.L) ≈ Lf
        @test sparse(Fs) ≈ As
        b = rand(Tv, 3)
        bs = sparse(b)
        @test Fs\b ≈ Af\b ≈ (Fs\bs)::SparseVector
        @test Fs.UP\(Fs.PtL\b) ≈ Af\b
        @test Fs.L\b ≈ Lf\b ≈ (Fs.L\bs)::SparseVector
        @test Fs.U\b ≈ Lf'\b ≈ (Fs.U\bs)::SparseVector
        @test Fs.L'\b ≈ Lf'\b ≈ (Fs.L'\bs)::SparseVector
        @test Fs.U'\b ≈ Lf\b ≈ (Fs.U'\bs)::SparseVector
        @test Fs.PtL\b ≈ Lf\b ≈ (Fs.PtL\bs)::SparseVector
        @test Fs.UP\b ≈ Lf'\b ≈ (Fs.UP\bs)::SparseVector
        @test Fs.PtL'\b ≈ Lf'\b ≈ (Fs.PtL'\bs)::SparseVector
        @test Fs.UP'\b ≈ Lf\b ≈ (Fs.UP'\bs)::SparseVector
        @test_throws CHOLMOD.CHOLMODException Fs.D
        @test_throws CHOLMOD.CHOLMODException Fs.LD
        @test_throws CHOLMOD.CHOLMODException Fs.DU
        @test_throws CHOLMOD.CHOLMODException Fs.PLD
        @test_throws CHOLMOD.CHOLMODException Fs.DUPt
    end

    @testset "cholesky, with permutation" begin
        Fs = cholesky(As, perm=p)
        @test Fs.p == p
        Afp = Af[p,p]
        Lfp = cholesky(Afp).L
        Ls = sparse(Fs.L)
        @test Ls ≈ Lfp
        @test Ls * Ls' ≈ Afp
        P = sparse(1:3, Fs.p, ones(Tv, 3))
        @test P' * Ls * Ls' * P ≈ As
        @test sparse(Fs) ≈ As
        b = rand(Tv, 3)
        bs = sparse(b)
        @test Fs\b ≈ Af\b ≈ (Fs\bs)::SparseVector
        @test Fs.UP\(Fs.PtL\b) ≈ Af\b
        @test Fs.L\b ≈ Lfp\b ≈ (Fs.L\bs)::SparseVector
        @test Fs.U'\b ≈ Lfp\b ≈ (Fs.U'\bs)::SparseVector
        @test Fs.U\b ≈ Lfp'\b ≈ (Fs.U\bs)::SparseVector
        @test Fs.L'\b ≈ Lfp'\b ≈ (Fs.L'\bs)::SparseVector
        @test Fs.PtL\b ≈ Lfp\b[p] ≈ (Fs.PtL\bs)::SparseVector
        @test Fs.UP\b ≈ (Lfp'\b)[p_inv] ≈ (Fs.UP\bs)::SparseVector
        @test Fs.PtL'\b ≈ (Lfp'\b)[p_inv] ≈ (Fs.PtL'\bs)::SparseVector
        @test Fs.UP'\b ≈ Lfp\b[p] ≈ (Fs.UP'\bs)::SparseVector
        @test_throws CHOLMOD.CHOLMODException Fs.PL
        @test_throws CHOLMOD.CHOLMODException Fs.UPt
        @test_throws CHOLMOD.CHOLMODException Fs.D
        @test_throws CHOLMOD.CHOLMODException Fs.LD
        @test_throws CHOLMOD.CHOLMODException Fs.DU
        @test_throws CHOLMOD.CHOLMODException Fs.PLD
        @test_throws CHOLMOD.CHOLMODException Fs.DUPt
    end

    @testset "ldlt, no permutation" begin
        Fs = ldlt(As, perm=[1:3;])
        @test Fs.p == [1:3;]
        @test sparse(Fs.LD) ≈ LDf
        @test sparse(Fs) ≈ As
        b = rand(Tv, 3)
        bs = sparse(b)
        @test Fs\b ≈ Af\b ≈ (Fs\bs)::SparseVector
        @test Fs.UP\(Fs.PtLD\b) ≈ Af\b
        @test Fs.DUP\(Fs.PtL\b) ≈ Af\b
        @test Fs.L\b ≈ L_f\b ≈ (Fs.L\bs)::SparseVector
        @test Fs.U\b ≈ L_f'\b ≈ (Fs.U\bs)::SparseVector
        @test Fs.L'\b ≈ L_f'\b
        @test Fs.U'\b ≈ L_f\b
        @test Fs.PtL\b ≈ L_f\b ≈ (Fs.PtL\bs)::SparseVector
        @test Fs.UP\b ≈ L_f'\b
        @test Fs.PtL'\b ≈ L_f'\b
        @test Fs.UP'\b ≈ L_f\b
        @test Fs.D\b ≈ D_f\b
        @test Fs.D'\b ≈ D_f\b
        @test Fs.LD\b ≈ D_f\(L_f\b)
        @test Fs.DU'\b ≈ D_f\(L_f\b)
        @test Fs.LD'\b ≈ L_f'\(D_f\b)
        @test Fs.DU\b ≈ L_f'\(D_f\b)
        @test Fs.PtLD\b ≈ D_f\(L_f\b)
        @test Fs.DUP'\b ≈ D_f\(L_f\b)
        @test Fs.PtLD'\b ≈ L_f'\(D_f\b)
        @test Fs.DUP\b ≈ L_f'\(D_f\b)
    end

    @testset "ldlt, with permutation" begin
        Fs = ldlt(As, perm=p)
        @test Fs.p == p
        @test sparse(Fs) ≈ As
        b = rand(Tv, 3)
        bs = sparse(b)
        Asp = As[p,p]
        LDp = sparse(ldlt(Asp, perm=[1,2,3]).LD)
        # LDp = sparse(Fs.LD)
        Lp, dp = CHOLMOD.getLd!(copy(LDp))
        Dp = sparse(Diagonal(dp))
        @test Fs\b ≈ Af\b ≈ (Fs\bs)::SparseVector
        @test Fs.UP\(Fs.PtLD\b) ≈ Af\b
        @test Fs.DUP\(Fs.PtL\b) ≈ Af\b
        @test Fs.L\b ≈ Lp\b ≈ (Fs.L\bs)::SparseVector
        @test Fs.U\b ≈ Lp'\b ≈ (Fs.U\bs)::SparseVector
        @test Fs.L'\b ≈ Lp'\b
        @test Fs.U'\b ≈ Lp\b
        @test Fs.PtL\b ≈ Lp\b[p] ≈ (Fs.PtL\bs)::SparseVector
        @test Fs.UP\b ≈ (Lp'\b)[p_inv]
        @test Fs.PtL'\b ≈ (Lp'\b)[p_inv]
        @test Fs.UP'\b ≈ Lp\b[p]
        @test Fs.LD\b ≈ Dp\(Lp\b)
        @test Fs.DU'\b ≈ Dp\(Lp\b)
        @test Fs.LD'\b ≈ Lp'\(Dp\b)
        @test Fs.DU\b ≈ Lp'\(Dp\b)
        @test Fs.PtLD\b ≈ Dp\(Lp\b[p])
        @test Fs.DUP'\b ≈ Dp\(Lp\b[p])
        @test Fs.PtLD'\b ≈ (Lp'\(Dp\b))[p_inv]
        @test Fs.DUP\b ≈ (Lp'\(Dp\b))[p_inv]
        @test_throws CHOLMOD.CHOLMODException Fs.DUPt
        @test_throws CHOLMOD.CHOLMODException Fs.PLD
    end

    @testset "Element promotion and type inference" begin
        @inferred cholesky(As)\fill(1, size(As, 1))
        @inferred ldlt(As)\fill(1, size(As, 1))
    end
end

@testset "Issue 11745 - row and column pointers were not sorted in sparse(Factor)" begin
    A = Tv[10 1 1 1; 1 10 0 0; 1 0 10 0; 1 0 0 10]
    @test sparse(cholesky(sparse(A))) ≈ A
end
GC.gc()

@testset "Issue 11747 - Wrong show method defined for FactorComponent" begin
    v = cholesky(sparse(Tv[ 10 1 1 1; 1 10 0 0; 1 0 10 0; 1 0 0 10])).L
    for s in (sprint(show, MIME("text/plain"), v), sprint(show, v))
        @test occursin("method:  simplicial", s)
        @test !occursin("#undef", s)
    end
end

@testset "Issue 29367" begin
    if Int != Int32
        @test_nowarn cholesky(sparse(Int32[1,2,3,4], Int32[1,2,3,4], Tv[1,4,16,64]))
        @test_nowarn ldlt(sparse(Int32[1,2,3,4], Int32[1,2,3,4], Tv[1,4,16,64]))
    end
end

@testset "Issue 14134" begin
    A = CHOLMOD.Sparse(sprandn(Tv, 10,5,0.1) + I |> t -> t't)
    b = IOBuffer()
    serialize(b, A)
    seekstart(b)
    Anew = deserialize(b)
    @test_throws ArgumentError show(Anew)
    @test_throws ArgumentError size(Anew)
    @test_throws ArgumentError Anew[1]
    @test_throws ArgumentError Anew[2,1]
    F = cholesky(A)
    serialize(b, F)
    seekstart(b)
    Fnew = deserialize(b)
    @test_throws ArgumentError Fnew\fill(1., 5)
    @test_throws ArgumentError show(Fnew)
    @test_throws ArgumentError size(Fnew)
    @test_throws ArgumentError diag(Fnew)
    @test_throws ArgumentError logdet(Fnew)
end

@testset "Issue #28985" begin
    @test typeof(cholesky(Tv.(sparse(I, 4, 4)))'\rand(Tv, 4)) == Array{Tv, 1}
    @test typeof(cholesky(Tv.(sparse(I, 4, 4)))'\rand(Tv, 4,1)) == Array{Tv, 2}
end

@testset "Issue with promotion during conversion to CHOLMOD.Dense" begin
    @test CHOLMOD.Dense(fill(1, 5)) == fill(1, 5, 1)
    @test CHOLMOD.Dense(fill(1f0, 5)) == fill(1, 5, 1)
    @test CHOLMOD.Dense(fill(1f0 + 0im, 5, 2)) == fill(1, 5, 2)
end

@testset "Further issue with promotion #14894" begin
    x = fill(1., 5)
    @test cholesky(sparse(Float16(1)I, 5, 5))\x == x
    @test cholesky(Symmetric(sparse(Float16(1)I, 5, 5)))\x == x
    @test cholesky(Hermitian(sparse(Complex{Float16}(1)I, 5, 5)))\x == x
    @test_throws TypeError cholesky(sparse(BigFloat(1)I, 5, 5))
    @test_throws TypeError cholesky(Symmetric(sparse(BigFloat(1)I, 5, 5)))
    @test_throws TypeError cholesky(Hermitian(sparse(Complex{BigFloat}(1)I, 5, 5)))
end

@testset "test \\ for Factor and StridedVecOrMat" begin
    x = rand(5)
    A = cholesky(sparse(Diagonal(x.\1)))
    @test A\view(fill(1.,10),1:2:10) ≈ x
    @test A\view(Matrix(1.0I, 5, 5), :, :) ≈ Matrix(Diagonal(x))
end

@testset "Test \\ for Factor and SparseVecOrMat" begin
    sparseI = sparse(1.0I, 100, 100)
    sparseb = sprandn(100, 0.5)
    sparseB = sprandn(100, 100, 0.5)
    chI = cholesky(sparseI)
    @test chI \ sparseb ≈ sparseb
    @test chI \ sparseB ≈ sparseB
    @test chI \ sparseI ≈ sparseI
end

@testset "Real factorization and complex rhs" begin
    A = sprandn(5, 5, 0.4) |> t -> t't + I
    B = complex.(randn(5, 5), randn(5, 5))
    b = B[:,1]
    @test cholesky(A)\b ≈ A\b
    @test cholesky(A)\B ≈ A\B
    @test cholesky(A)\B' ≈ A\B'
    @test cholesky(A)\transpose(B) ≈ A\transpose(B)
    @test cholesky(A)'\b ≈ copy(A')\b
    @test cholesky(A)'\B ≈ copy(A')\B
    @test cholesky(A)'\B' ≈ copy(A')\B'
    @test cholesky(A)'\transpose(B) ≈ copy(A')\transpose(B)
end

@testset "Make sure that ldlt performs an LDLt (Issue #19032)" begin
    m, n = 400, 500
    A = sprandn(m, n, .2)
    M = [I copy(A'); A -I]
    b = M * fill(1., m+n)
    F = ldlt(M)
    s = unsafe_load(pointer(F))
    @test s.is_super == 0
    @test F\b ≈ fill(1., m+n)
    F2 = cholesky(M; check = false)
    @test !issuccess(F2)
    ldlt!(F2, M)
    @test issuccess(F2)
    @test F2\b ≈ fill(1., m+n)
end

@testset "Test that imaginary parts in Hermitian{T,SparseMatrixCSC{T}} are ignored" begin
    A = sparse([1,2,3,4,1], [1,2,3,4,2], [complex(2.0,1),2,2,2,1])
    Fs = cholesky(Hermitian(A))
    Fd = cholesky(Hermitian(Array(A)))
    @test sparse(Fs) ≈ Hermitian(A)
    @test Fs\fill(1., 4) ≈ Fd\fill(1., 4)
end

@testset "\\ '\\ and transpose(...)\\" begin
    # Test that \ and '\ and transpose(...)\ work for Symmetric and Hermitian. This is just
    # a dispatch exercise so it doesn't matter that the complex matrix has
    # zero imaginary parts
    Apre = sprandn(Tv, 10, 10, 0.2) - I
    for A in (Symmetric(Apre), Hermitian(Apre),
              Symmetric(Apre + 10I), Hermitian(Apre + 10I),
              Hermitian(complex(Apre)), Hermitian(complex(Apre) + 10I))
        local A, x, b
        x = fill(1., 10)
        b = A*x
        @test x ≈ A\b
        @test transpose(A)\b ≈ A'\b
    end
end

@testset "Check that Symmetric{SparseMatrixCSC} can be constructed from CHOLMOD.Sparse" begin
    Int === Int32 && Random.seed!(124)
    A = sprandn(Tv, 10, 10, 0.1)
    B = CHOLMOD.Sparse(A)
    C = B'B
    # Change internal representation to symmetric (upper/lower)
    o = fieldoffset(cholmod_sparse, findall(fieldnames(cholmod_sparse) .== :stype)[1])
    for uplo in (1, -1)
        unsafe_store!(Ptr{Int8}(pointer(C)), uplo, Int(o) + 1)
        @test convert(Symmetric{Tv,SparseMatrixCSC{Tv,Int}}, C) ≈ Symmetric(A'A)
    end
end

@testset "sparse right multiplication of Symmetric and Hermitian matrices #21431" begin
    S = sparse(1.0I, 2, 2)
    @test issparse(S*S*S)
    for T in (Symmetric, Hermitian)
        @test issparse(S*T(S)*S)
        @test issparse(S*(T(S)*S))
        @test issparse((S*T(S))*S)
    end
end

@testset "Test sparse low rank update for cholesky decomposition" begin
    A = SparseMatrixCSC{Tv,Int}(10, 5, [1,3,6,8,10,13], [6,7,1,2,9,3,5,1,7,6,7,9],
        Tv[-0.138843, 2.99571, -0.556814, 0.669704, -1.39252, 1.33814,
        1.02371, -0.502384, 1.10686, 0.262229, -1.6935, 0.525239])
    AtA = A'*A
    C0 = Tv[1., 2., 0, 0, 0]
    # Test both cholesky and LDLt with and without automatic permutations
    for F in (cholesky(AtA), cholesky(AtA, perm=1:5), ldlt(AtA), ldlt(AtA, perm=1:5))
        local F
        x0 = F\(b = ones(Tv, 5))
        #Test both sparse/dense and vectors/matrices
        for Ctest in (C0, sparse(C0), [C0 2*C0], sparse([C0 2*C0]))
            local x, C, F1
            C = copy(Ctest)
            F1 = copy(F)
            x = (AtA+C*C')\b

            #Test update
            F11 = CHOLMOD.lowrankupdate(F1, C)
            @test Array(sparse(F11)) ≈ AtA+C*C'
            @test F11\b ≈ x
            #Make sure we get back the same factor again
            F10 = CHOLMOD.lowrankdowndate(F11, C)
            @test Array(sparse(F10)) ≈ AtA
            @test F10\b ≈ x0

            #Test in-place update
            CHOLMOD.lowrankupdate!(F1, C)
            @test Array(sparse(F1)) ≈ AtA+C*C'
            @test F1\b ≈ x
            #Test in-place downdate
            CHOLMOD.lowrankdowndate!(F1, C)
            @test Array(sparse(F1)) ≈ AtA
            @test F1\b ≈ x0

            @test C == Ctest    #Make sure C didn't change
        end
    end
end

@testset "Issue #22335" begin
    local A, F
    A = sparse(1.0I, 3, 3)
    @test issuccess(cholesky(A))
    A[3, 3] = -1
    F = cholesky(A; check = false)
    @test !issuccess(F)
    @test issuccess(ldlt!(F, A))
    A[3, 3] = 1
    @test A[:, 3:-1:1]\fill(1., 3) == [1, 1, 1]
end

@testset "Non-positive definite matrices" begin
    A = sparse(Tv[1 2; 2 1])
    B = sparse(Complex{Tv}[1 2; 2 1])
    for M in (A, B, Symmetric(A), Hermitian(B))
        F = cholesky(M; check = false)
        @test_throws PosDefException cholesky(M)
        @test_throws PosDefException cholesky!(F, M)
        @test !issuccess(cholesky(M; check = false))
        @test !issuccess(cholesky!(F, M; check = false))
    end
    A = sparse(Tv[0 0; 0 0])
    B = sparse(Complex{Tv}[0 0; 0 0])
    for M in (A, B, Symmetric(A), Hermitian(B))
        F = ldlt(M; check = false)
        @test_throws ZeroPivotException ldlt(M)
        @test_throws ZeroPivotException ldlt!(F, M)
        @test !issuccess(ldlt(M; check = false))
        @test !issuccess(ldlt!(F, M; check = false))
    end
end

@testset "Issues #27860 & #28363" begin
    for typeA in (Tv, Complex{Tv}), typeB in (Tv, Complex{Tv}), transform in (identity, adjoint, transpose)
        A = sparse(typeA[2.0 0.1; 0.1 2.0])
        B = randn(typeB, 2, 2)
        @test A \ transform(B) ≈ cholesky(A) \ transform(B) ≈ Matrix(A) \ transform(B)
        C = randn(typeA, 2, 2)
        sC = sparse(C)
        sF = typeA <: Real ? cholesky(Symmetric(A)) : cholesky(Hermitian(A))
        @test cholesky(A) \ transform(sC) ≈ Matrix(A) \ transform(C)
        @test sF.PtL \ transform(A) ≈ sF.PtL \ Matrix(transform(A))
    end
end

@testset "Issue #33365" begin
    A = Sparse(spzeros(Tv, 0, 0))
    @test A * A' == A
    @test A' * A == A
    B = Sparse(spzeros(Tv, 0, 4))
    @test B * B' == Sparse(spzeros(Tv, 0, 0))
    @test B' * B == Sparse(spzeros(Tv, 4, 4))
    C = Sparse(spzeros(Tv, 3, 0))
    @test C * C' == Sparse(spzeros(Tv, 3, 3))
    @test C' * C == Sparse(spzeros(Tv, 0, 0))
end

@testset "permutation handling" begin
    @testset "default permutation" begin
        # Assemble arrow matrix
        A = sparse(5I,3,3)
        A[:,1] .= 1; A[1,:] .= A[:,1]

        # Ensure cholesky eliminates the fill-in
        @test cholesky(A).p[1] != 1
    end

    @testset "user-specified permutation" begin
        n = 100
        A = sprand(Tv, n,n,5/n) |> t -> t't + I
        @test cholesky(A, perm=1:n).p == 1:n
    end
end

@testset "sym indefinite poly alg" begin
    K = open(joinpath(@__DIR__, "matrices", "stiffness_sym_indef")) do io
        ml = readline(io)
        m = parse(Int, split(ml, "m = ")[2])
        nl = readline(io)
        n = parse(Int, split(nl, "n = ")[2])

        colptrl = readline(io)
        rowvall = readline(io)
        nzvall = readline(io)

        colptr = parse.(Int,     split(strip(split(colptrl, "colptr = ")[2], [']', '[']), ','))
        rowval = parse.(Int,     split(strip(split(rowvall, "rowval = ")[2], [']', '[']), ','))
        nzval =  parse.(Float64, split(strip(split(nzvall, "nzval = ")[2], [']', '[']), ','))

        SparseMatrixCSC(m, n, colptr, rowval, nzval)
    end

    f = ones(size(K, 1))
    u = K \ f
    residual = norm(f - K * u) / norm(f)
    @test residual < 1e-6
end

@testset "wrapped sparse matrices" begin
    A = I + sprand(Tv, 10, 10, 0.1); A = A'A
    @test issuccess(cholesky(view(A, :, :)))
    @test issuccess(cholesky(Symmetric(view(A, :, :))))
    @test_throws ErrorException cholesky(view(A, :, :), RowMaximum())
    # turn on once two-arg cholesky is made to forward any PivotingStrategy argument
    # @test_throws ErrorException cholesky(A, NoPivot())
    # @test_throws ErrorException cholesky(view(A, :, :), NoPivot())
end

@testset "solve with adjoint factorization and adjoint rhs" begin
    n = 10
    A = sprand(Tv, n, n, 1/n)
    A = A + A' + 10I

    B = rand(n, 2)
    Bt = Matrix(B')
    Bts = sparse(B')

    F = cholesky(A)'
    @test F \ B ≈ F \ Bt'
    @test F \ B ≈ F \ Bts'
    @test issparse(F \ Bts')
end

end # for Tv ∈ (Float32, Float64)

end # Base.USE_GPL_LIBS

end # module
