"""

    momentupdat(M::SymmetricTensor{Float, N}, X::Matrix, Xup::Matrix)

Returns SymmetricTensor{Float, N} updated moment, given original moment, original data and update
of data - dataup
"""

function momentupdat(M::SymmetricTensor{T, N}, X::Matrix{T}, Xup::Matrix{T}) where T<:AbstractFloat where N
  tup = size(Xup,1)
  M + tup/size(X, 1)*(moment(Xup, N, M.bls) - moment(X[1:tup,:], N, M.bls))
end

"""

  momentupdat(M::Vector{SymmetricTensor{T}}, X::Matrix{T}, Xup::Matrix{T})

  Returns Vector{SymmetricTensor} of updated moments

"""

momentupdat(M::Vector{SymmetricTensor{T}}, X::Matrix{T}, Xup::Matrix{T}) where T <: AbstractFloat =
    [momentupdat(M[i], X, Xup) for i in 1:length(M)]


"""
  momentarray(X::Matrix{Float}, m::Int, b::Int)

Returns an array of Symmetric Tensors of moments given data and maximum moment order
"""

momentarray(X::Matrix{T}, m::Int = 4, b::Int = 2) where T <: AbstractFloat =
    [moment(X, i, b) for i in 1:m]

"""

  moms2cums!(M::Vector{SymmetricTensor})

Changes vector of Symmetric Tensors of moments to vector of Symmetric Tensors of cumulants
"""


function moms2cums!(M::Vector{SymmetricTensor{T}}) where T <: AbstractFloat
  m = length(M)
  for i in 1:m
    f(sigma::Int) = outerprodcum(i, sigma, M...; exclpartlen = 0)
    prods = pmap(f, [(2:m)...])
    for k in 2:m
      @inbounds M[i] -= prods[k-1]
    end
  end
end

"""

  cums2moms(cum::Vector{SymmetricTensor})

Returns vector of Symmetric Tensors of moments given vector of Symmetric Tensors
of cumulants
"""


function cums2moms(cum::Vector{SymmetricTensor{T}}) where T <: AbstractFloat
  m = length(cum)
  Mvec = Array{SymmetricTensor{T}}(m)
  for i in 1:m
    f(σ::Int) = outerprodcum(i, σ, cum...; exclpartlen = 0)
    @inbounds Mvec[i] = cum[i]
    prods = pmap(f, [(2:m)...])
    for k in 2:m
      @inbounds Mvec[i] += prods[k-1]
    end
  end
  Mvec
end

"""
  cumulantsupdat(X::Matrix{T}, m::Int = 4, b::Int = 4)

Returns a a vector of SymmetricTensors of cumulants of order 1, ..., m calculated.
Moments array are saved in tmp/cumdata.jld for further cumulants updates,
parameter b is the block size for the block structure of cumulants.
"""

cumulantsupdat(X::Matrix{T}, m::Int = 4, b::Int = 4) where T <: AbstractFloat =
  cumulantsupdat(X, zeros(0, size(X,2)), m, b)

"""
  cumulantsupdat(X::Matrix{T}, Xup::Matrix{T}, m::Int = 4, b::Int = 4)

Returns a vector of SymmetricTensors of cumulants of order 1, ..., m calculated
for X, updated by Xup. Loads moments arrays and saves updated moment
arrays in /tmp/cumdata.jld b - the block size for the block structure of cumulants.
"""

function cumulantsupdat(X::Matrix{T}, Xup::Matrix{T}, m::Int = 4, b::Int = 4) where T <: AbstractFloat
  Xp = vcat(X, Xup)[(size(Xup, 1)+1):end,:]
  cpath = "/tmp/cumdata.jld"
  d = try load(cpath) catch end
  X1 = try(d["x"]) catch end
  M = try(d["M"]) catch [1.] end
  if ((length(M) == m) & (X1 == X) & (typeof(M[1]) <: SymmetricTensor))
    Mup = momentupdat(M, X, Xup)
    println("load")
  else
    Mup = momentarray(Xp, m, b)
    println("comp")
  end
  try save(cpath, "M", Mup, "x", Xp) catch end
  moms2cums!(Mup)
  Mup
end



function updat(M::Vector{SymmetricTensor{T}}, X::Matrix{T}, Xup::Matrix{T}) where T <: AbstractFloat
  @inbounds Mup = momsupdat(M, X, Xup)
  moms2cums!(Mup)
  Mup
end
