// Physical State Bounds, Safety Guardrails and Anomaly Detectors

///|
pub(all) struct BoundsViolation {
  variable_id : String
  attempted_value : Double
  bound_limit : Double
  violation_type : String
} derive(Debug)

///|
pub fn BoundsViolation::new(
  id : String,
  val : Double,
  limit : Double,
  v_type : String,
) -> BoundsViolation {
  {
    variable_id: id,
    attempted_value: val,
    bound_limit: limit,
    violation_type: v_type,
  }
}

///|
pub fn validate_state_vector_bounds(
  state : StateVector,
) -> Array[BoundsViolation] {
  let violations = Array::new()
  for i = 0; i < state.vars.length(); i = i + 1 {
    let v = state.vars[i]
    if v.value < v.min_val {
      violations.push(
        BoundsViolation::new(v.id, v.value, v.min_val, "UNDERFLOW_BELOW_MIN"),
      )
    }
    if v.value > v.max_val {
      violations.push(
        BoundsViolation::new(v.id, v.value, v.max_val, "OVERFLOW_ABOVE_MAX"),
      )
    }
  }
  violations
}

///|
pub fn sanitize_nan_values(
  vals : Array[Double],
  fallback : Double,
) -> Array[Double] {
  let cleaned = Array::make(vals.length(), 0.0)
  for i = 0; i < vals.length(); i = i + 1 {
    let v = vals[i]
    // Check NaN or Inf approximation
    if v != v || v > 1.0e30 || v < -1.0e30 {
      cleaned[i] = fallback
    } else {
      cleaned[i] = v
    }
  }
  cleaned
}
