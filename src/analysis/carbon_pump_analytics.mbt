// Marine Biological Carbon Pump & Martin Curve Attenuation Diagnostics

///|
pub(all) struct CarbonPumpMetrics {
  surface_primary_production : Double
  export_flux_100m : Double
  deep_flux_1000m : Double
  export_ratio_pe : Double
  transfer_efficiency : Double
} derive(Debug)

///|
pub fn compute_martin_curve_attenuation(
  flux_at_ref_depth : Double,
  ref_depth_m : Double,
  target_depth_m : Double,
  b_exponent : Double,
) -> Double {
  // Martin et al. (1987) attenuation power law: F(z) = F(z0) * (z / z0)^(-b)
  if target_depth_m <= ref_depth_m || ref_depth_m <= 0.0 {
    flux_at_ref_depth
  } else {
    let ratio = target_depth_m / ref_depth_m
    flux_at_ref_depth * @math.pow(ratio, -b_exponent)
  }
}

///|
pub fn analyze_biological_carbon_pump(
  primary_production : Double,
  export_flux_100m : Double,
  martin_b_exponent : Double,
) -> CarbonPumpMetrics {
  let flux_1000m = compute_martin_curve_attenuation(
    export_flux_100m, 100.0, 1000.0, martin_b_exponent,
  )

  let pe_ratio = if primary_production > 1.0e-9 {
    export_flux_100m / primary_production
  } else {
    0.0
  }

  let t_eff = if export_flux_100m > 1.0e-9 {
    flux_1000m / export_flux_100m
  } else {
    0.0
  }

  {
    surface_primary_production: primary_production,
    export_flux_100m,
    deep_flux_1000m: flux_1000m,
    export_ratio_pe: pe_ratio,
    transfer_efficiency: t_eff,
  }
}
