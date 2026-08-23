// Checked construction, inventory, and explicit transport diagnostics for 1D columns.

///|
pub(all) struct WaterColumnDiagnostics {
  layer_count : Int
  state_dimension : Int
  total_inventory : Double
  minimum_concentration : Double
  maximum_concentration : Double
  non_negative : Bool
  maximum_cfl : Double
  stable : Bool
  stable_dt_upper_bound : Double
} derive(Debug)

///|
fn finite_column_value(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
pub fn WaterColumn1D::try_create(
  num_layers : Int,
  total_depth_m : Double,
  initial_conc : Array[Double],
) -> Result[WaterColumn1D, String] {
  if num_layers <= 0 {
    return Err("Water column requires at least one layer")
  }
  if !finite_column_value(total_depth_m) || total_depth_m <= 0.0 {
    return Err("Water column depth must be finite and positive")
  }
  if initial_conc.length() == 0 {
    return Err("Water column requires at least one state variable")
  }
  for value in initial_conc {
    if !finite_column_value(value) {
      return Err("Water column concentrations must be finite")
    }
    if value < 0.0 {
      return Err("Water column concentrations must be non-negative")
    }
  }
  Ok(WaterColumn1D::create(num_layers, total_depth_m, initial_conc))
}

///|
pub fn validate_water_column(
  column : WaterColumn1D,
) -> Result[WaterColumnDiagnostics, String] {
  if column.num_layers <= 0 || column.layers.length() == 0 {
    return Err("Water column must contain at least one layer")
  }
  if !finite_column_value(column.total_depth_m) || column.total_depth_m <= 0.0 {
    return Err("Water column depth must be finite and positive")
  }
  let state_dimension = column.layers[0].state.length()
  if state_dimension == 0 {
    return Err("Water column layers require at least one state variable")
  }
  let reference_dz = column.layers[0].dz_m
  if !finite_column_value(reference_dz) || reference_dz <= 0.0 {
    return Err("Water column layer spacing must be finite and positive")
  }

  let mut total_inventory = 0.0
  let mut minimum_concentration = column.layers[0].state[0]
  let mut maximum_concentration = column.layers[0].state[0]
  for i = 0; i < column.layers.length(); i = i + 1 {
    let layer = column.layers[i]
    if layer.state.length() != state_dimension {
      return Err("Water column layers must have equal state dimensions")
    }
    if !finite_column_value(layer.depth_m) || !finite_column_value(layer.dz_m) ||
      layer.dz_m <= 0.0 {
      return Err("Water column layer geometry must be finite and positive")
    }
    if (layer.dz_m - reference_dz).abs() > 1.0e-9 {
      return Err("Water column layers must use equal spacing")
    }
    if !finite_column_value(layer.temperature) || !finite_column_value(layer.par) {
      return Err("Water column environmental fields must be finite")
    }
    for value in layer.state {
      if !finite_column_value(value) {
        return Err("Water column concentrations must be finite")
      }
      if value < 0.0 {
        return Err("Water column concentrations must be non-negative")
      }
      total_inventory = total_inventory + value * layer.dz_m
      if value < minimum_concentration {
        minimum_concentration = value
      }
      if value > maximum_concentration {
        maximum_concentration = value
      }
    }
  }

  Ok({
    layer_count: column.layers.length(),
    state_dimension,
    total_inventory,
    minimum_concentration,
    maximum_concentration,
    non_negative: true,
    maximum_cfl: 0.0,
    stable: true,
    stable_dt_upper_bound: 0.0,
  })
}

///|
pub fn water_column_stability_limit(
  dz_m : Double,
  kz_m2_day : Double,
  w_sinking_m_day : Double,
) -> Result[Double, String] {
  if !finite_column_value(dz_m) || dz_m <= 0.0 {
    return Err("Transport layer spacing must be finite and positive")
  }
  if !finite_column_value(kz_m2_day) || kz_m2_day < 0.0 {
    return Err("Diffusivity must be finite and non-negative")
  }
  if !finite_column_value(w_sinking_m_day) {
    return Err("Sinking velocity must be finite")
  }
  let diffusion_rate = 2.0 * kz_m2_day / (dz_m * dz_m)
  let advection_rate = w_sinking_m_day.abs() / dz_m
  let combined_rate = diffusion_rate + advection_rate
  if combined_rate == 0.0 {
    return Ok(1.0e12)
  }
  Ok(1.0 / combined_rate)
}

///|
pub fn assess_water_column_step(
  column : WaterColumn1D,
  kz_m2_day : Double,
  w_sinking_m_day : Double,
  dt : Double,
) -> Result[WaterColumnDiagnostics, String] {
  let base_report = match validate_water_column(column) {
    Ok(report) => report
    Err(err) => return Err(err)
  }
  if !finite_column_value(dt) || dt <= 0.0 {
    return Err("Water column dt must be finite and positive")
  }
  let dz = column.layers[0].dz_m
  let limit = match water_column_stability_limit(dz, kz_m2_day, w_sinking_m_day) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let maximum_cfl = if limit >= 1.0e11 { 0.0 } else { dt / limit }
  Ok({
    layer_count: base_report.layer_count,
    state_dimension: base_report.state_dimension,
    total_inventory: base_report.total_inventory,
    minimum_concentration: base_report.minimum_concentration,
    maximum_concentration: base_report.maximum_concentration,
    non_negative: base_report.non_negative,
    maximum_cfl,
    stable: maximum_cfl <= 1.0,
    stable_dt_upper_bound: limit,
  })
}
