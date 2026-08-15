// 1D Vertical Multi-Layer Water Column Grid Extension

///|
pub(all) struct VerticalLayer {
  layer_index : Int
  depth_m : Double
  dz_m : Double
  temperature : Double
  par : Double
  state : Array[Double]
} derive(Debug)

///|
pub(all) struct WaterColumn1D {
  num_layers : Int
  total_depth_m : Double
  layers : Array[VerticalLayer]
  kz_m2_day : Double
} derive(Debug)

///|
pub fn WaterColumn1D::create(
  num_layers : Int,
  total_depth_m : Double,
  initial_conc : Array[Double],
) -> WaterColumn1D {
  let dz = total_depth_m / num_layers.to_double()
  let layers = Array::make(num_layers, {
    layer_index: 0,
    depth_m: 0.0,
    dz_m: dz,
    temperature: 15.0,
    par: 100.0,
    state: initial_conc,
  })

  for i = 0; i < num_layers; i = i + 1 {
    let depth = (i.to_double() + 0.5) * dz
    let temp = 18.0 - 10.0 * (depth / total_depth_m)
    let par = 200.0 * @math.exp(-0.05 * depth)
    layers[i] = {
      layer_index: i,
      depth_m: depth,
      dz_m: dz,
      temperature: temp,
      par,
      state: initial_conc.copy(),
    }
  }

  { num_layers, total_depth_m, layers, kz_m2_day: 1.0 }
}

///|
pub fn WaterColumn1D::compute_vertical_diffusion(
  self : WaterColumn1D,
  state_idx : Int,
) -> Array[Double] {
  let n = self.num_layers
  let d2c = Array::make(n, 0.0)
  let dz = self.total_depth_m / n.to_double()
  let coeff = self.kz_m2_day / (dz * dz)

  for i = 0; i < n; i = i + 1 {
    let c_curr = self.layers[i].state[state_idx]
    let c_above = if i > 0 {
      self.layers[i - 1].state[state_idx]
    } else {
      c_curr
    }
    let c_below = if i < n - 1 {
      self.layers[i + 1].state[state_idx]
    } else {
      c_curr
    }

    d2c[i] = coeff * (c_above - 2.0 * c_curr + c_below)
  }

  d2c
}
