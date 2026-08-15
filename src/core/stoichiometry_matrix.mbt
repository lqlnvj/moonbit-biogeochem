// Multi-Element Stoichiometric Matrix Transformation & Ratio Converter

///|
pub(all) struct ElementVector {
  c_val : Double
  n_val : Double
  p_val : Double
  si_val : Double
  o2_val : Double
} derive(Debug, Eq)

///|
pub fn ElementVector::new(
  c : Double,
  n : Double,
  p : Double,
  si : Double,
  o2 : Double,
) -> ElementVector {
  { c_val: c, n_val: n, p_val: p, si_val: si, o2_val: o2 }
}

///|
pub fn ElementVector::from_nitrogen(
  n : Double,
  redfield : RedfieldRatio,
  si_n_ratio : Double,
) -> ElementVector {
  let c = n * redfield.c_to_n()
  let p = n / redfield.n_ratio
  let si = n * si_n_ratio
  let o2 = n * redfield.o2_to_n()
  { c_val: c, n_val: n, p_val: p, si_val: si, o2_val: o2 }
}

///|
pub fn ElementVector::scale(
  self : ElementVector,
  factor : Double,
) -> ElementVector {
  {
    c_val: self.c_val * factor,
    n_val: self.n_val * factor,
    p_val: self.p_val * factor,
    si_val: self.si_val * factor,
    o2_val: self.o2_val * factor,
  }
}
