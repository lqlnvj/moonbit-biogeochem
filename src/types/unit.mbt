// Physical and Chemical Units & Dimensional Analysis for Ocean Biogeochemistry

pub(all) enum UnitCategory {
  ConcentrationN  // mmol N / m^3
  ConcentrationP  // mmol P / m^3
  ConcentrationC  // mmol C / m^3
  ConcentrationO  // mmol O2 / m^3
  ConcentrationMass // mg / L or g / m^3
  RatePerDay      // day^-1
  RatePerSecond   // s^-1
  Flux            // mmol / (m^2 * day)
  Velocity        // m / day
  Depth           // m
  Temperature     // Celsius
  Salinity        // PSU (Practical Salinity Unit)
  Irradiance      // W / m^2 or uE / (m^2 * s)
  Pressure        // dbar or atm
  Dimensionless   // 1
} derive(Debug, Eq, Compare)

pub(all) struct PhysicalQuantity {
  value : Double
  unit : UnitCategory
  name : String
} derive(Debug)

pub fn PhysicalQuantity::new(value : Double, unit : UnitCategory, name : String) -> PhysicalQuantity {
  { value, unit, name }
}

pub fn PhysicalQuantity::dimensionless(value : Double, name : String) -> PhysicalQuantity {
  { value, unit: Dimensionless, name }
}

pub fn PhysicalQuantity::convert_concentration_n_to_mass(q : PhysicalQuantity) -> Result[PhysicalQuantity, String] {
  match q.unit {
    ConcentrationN => {
      // 1 mmol N = 14.0067 mg N
      let mg_l = q.value * 14.0067 / 1000.0
      Ok({ value: mg_l, unit: ConcentrationMass, name: q.name + " (mg N/L)" })
    }
    _ => Err("Invalid unit conversion: expected ConcentrationN")
  }
}

pub fn PhysicalQuantity::convert_rate_day_to_sec(q : PhysicalQuantity) -> Result[PhysicalQuantity, String] {
  match q.unit {
    RatePerDay => {
      let per_sec = q.value / 86400.0
      Ok({ value: per_sec, unit: RatePerSecond, name: q.name + " (s^-1)" })
    }
    _ => Err("Invalid unit conversion: expected RatePerDay")
  }
}

pub fn check_unit_compatibility(u1 : UnitCategory, u2 : UnitCategory) -> Bool {
  u1 == u2
}

pub fn scale_quantity(q : PhysicalQuantity, factor : Double) -> PhysicalQuantity {
  { value: q.value * factor, unit: q.unit, name: q.name }
}

pub fn add_quantities(q1 : PhysicalQuantity, q2 : PhysicalQuantity) -> Result[PhysicalQuantity, String] {
  if check_unit_compatibility(q1.unit, q2.unit) {
    Ok({ value: q1.value + q2.value, unit: q1.unit, name: q1.name + " + " + q2.name })
  } else {
    Err("Unit mismatch: cannot add " + unit_symbol(q1.unit) + " and " + unit_symbol(q2.unit))
  }
}

pub fn sub_quantities(q1 : PhysicalQuantity, q2 : PhysicalQuantity) -> Result[PhysicalQuantity, String] {
  if check_unit_compatibility(q1.unit, q2.unit) {
    Ok({ value: q1.value - q2.value, unit: q1.unit, name: q1.name + " - " + q2.name })
  } else {
    Err("Unit mismatch: cannot subtract " + unit_symbol(q1.unit) + " and " + unit_symbol(q2.unit))
  }
}

pub fn unit_symbol(unit : UnitCategory) -> String {
  match unit {
    ConcentrationN => "mmol N m⁻³"
    ConcentrationP => "mmol P m⁻³"
    ConcentrationC => "mmol C m⁻³"
    ConcentrationO => "mmol O₂ m⁻³"
    ConcentrationMass => "mg L⁻¹"
    RatePerDay => "d⁻¹"
    RatePerSecond => "s⁻¹"
    Flux => "mmol m⁻² d⁻¹"
    Velocity => "m d⁻¹"
    Depth => "m"
    Temperature => "°C"
    Salinity => "PSU"
    Irradiance => "W m⁻²"
    Pressure => "dbar"
    Dimensionless => "-"
  }
}
