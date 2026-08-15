// 1D Vertical Advection-Diffusion-Reaction Numerical Solver

///|
pub fn solve_advection_diffusion_step(
  conc : Array[Double],
  dz_m : Double,
  kz_m2_day : Double,
  w_sinking_m_day : Double,
  dt : Double,
) -> Array[Double] {
  let n = conc.length()
  let next_c = Array::make(n, 0.0)

  let diff_coeff = kz_m2_day / (dz_m * dz_m)
  let adv_coeff = w_sinking_m_day / dz_m

  for i = 0; i < n; i = i + 1 {
    let c = conc[i]
    let c_up = if i > 0 { conc[i - 1] } else { conc[0] }
    let c_down = if i < n - 1 { conc[i + 1] } else { conc[n - 1] }

    // Diffusion term: Kz * d2C/dz2
    let diffusion = diff_coeff * (c_up - 2.0 * c + c_down)
    // Upwind advection term: - w * dC/dz
    let advection = -adv_coeff * (c - c_up)

    let updated = c + dt * (diffusion + advection)
    next_c[i] = if updated < 0.0 { 0.0 } else { updated }
  }

  next_c
}
