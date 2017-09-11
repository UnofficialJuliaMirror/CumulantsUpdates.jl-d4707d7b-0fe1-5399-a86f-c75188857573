"""

    momentupdat(M::SymmetricTensor{Float, N}, X::Matrix, Xup::Matrix)

Returns SymmetricTensor{Float, N} updated moment, given original moment, original data and update
of data - dataup
"""

function momentupdat{T<:AbstractFloat, N}(M::SymmetricTensor{T, N}, X::Matrix{T}, Xup::Matrix{T})
  tup = size(Xup,1)
  M + tup/size(X, 1)*(moment(Xup, N, M.bls) - moment(X[1:tup,:], N, M.bls))
end


"""
  momentarray(X::Matrix{Float}, m::Int, b::Int)

Returns an array of Symmetric Tensors of moments given data and maximum moment order
"""


momentarray{T <: AbstractFloat}(X::Matrix{T}, m::Int = 4, b::Int = 2) =
                              [moment(X, i, b) for i in 1:m]


"""

  moms2cums!(M::Vector{SymmetricTensor})

Changes vector of Symmetric Tensors of moments to vector of Symmetric Tensors of cumulants
"""


function moms2cums!{T<:AbstractFloat}(M::Vector{SymmetricTensor{T}})
  for i in 1:length(M)
    for sigma in 2:i
      @inbounds M[i] -= outerprodcum(i, sigma, M[1:(i-1)]...; exclpartlen = 0)
    end
  end
end


"""

  cums2moms(cum::Vector{SymmetricTensor})

Returns vector of Symmetric Tensors of moments given vector of Symmetric Tensors
of cumulants
"""

function cums2moms{T <: AbstractFloat}(cum::Vector{SymmetricTensor{T}})
  m = length(cum)
  Mvec = Array{SymmetricTensor{T}}(m)
  for i in 1:m
    Mvec[i] = cum[i]
    for sigma in 2:i
      Mvec[i] += outerprodcum(i, sigma, cum...; exclpartlen = 0)
    end
  end
  Mvec
end


"""

    cumulantsupdat{T<:AbstractFloat}(cum::Vector{SymmetricTensor}, X::Matrix, Xup::Matrix)

Returns Vector{SymmetricTensor} of updated cumulants

"""

function cumulantsupdat{T<:AbstractFloat}(cum::Vector{SymmetricTensor{T}}, X::Matrix{T},
                                                                          Xup::Matrix{T})
  M = cums2moms(cum)
  @inbounds Mup = [momentupdat(M[i], X, Xup) for i in 1:length(cum)]
  moms2cums!(Mup)
  Mup
end
