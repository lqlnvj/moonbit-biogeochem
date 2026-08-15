// Redfield Ratio Stoichiometry and Mass Conservation Auditor

///|
pub(all) struct RedfieldRatio {
  c_ratio : Double // Carbon ratio relative to Phosphorus (106)
  n_ratio : Double // Nitrogen ratio relative to Phosphorus (16)
  p_ratio : Double // Phosphorus ratio (1)
  o2_ratio : Double // Oxygen consumption ratio (-138)
} derive(Debug, Eq)

///|
pub fn RedfieldRatio::standard() -> RedfieldRatio {
  { c_ratio: 106.0, n_ratio: 16.0, p_ratio: 1.0, o2_ratio: 138.0 }
}

///|
pub fn RedfieldRatio::n_to_c(self : RedfieldRatio) -> Double {
  self.n_ratio / self.c_ratio
}

///|
pub fn RedfieldRatio::c_to_n(self : RedfieldRatio) -> Double {
  self.c_ratio / self.n_ratio
}

///|
pub fn RedfieldRatio::o2_to_c(self : RedfieldRatio) -> Double {
  self.o2_ratio / self.c_ratio
}

///|
pub fn RedfieldRatio::o2_to_n(self : RedfieldRatio) -> Double {
  self.o2_ratio / self.n_ratio
}

///|
pub(all) struct MassConservationCheck {
  total_element_initial : Double
  total_element_current : Double
  absolute_error : Double
  relative_error : Double
  is_conserved : Bool
} derive(Debug)

///|
pub fn MassConservationCheck::audit(
  initial_total : Double,
  current_total : Double,
  tolerance : Double,
) -> MassConservationCheck {
  let abs_err = (current_total - initial_total).abs()
  let rel_err = if initial_total > 1.0e-12 {
    abs_err / initial_total
  } else {
    abs_err
  }
  let conserved = rel_err <= tolerance
  {
    total_element_initial: initial_total,
    total_element_current: current_total,
    absolute_error: abs_err,
    relative_error: rel_err,
    is_conserved: conserved,
  }
}
