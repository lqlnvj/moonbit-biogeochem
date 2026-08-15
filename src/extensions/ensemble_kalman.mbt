// Ensemble Kalman Filter (EnKF) Data Assimilation Engine

///|
pub(all) struct EnsembleFilterState {
  ensemble_size : Int
  states : Array[@types.StateVector]
} derive(Debug)

///|
pub fn EnsembleFilterState::create(
  initial_state : @types.StateVector,
  num_members : Int,
) -> EnsembleFilterState {
  let members = Array::make(num_members, initial_state)
  let base_arr = initial_state.to_array()
  let dim = base_arr.length()

  for m = 0; m < num_members; m = m + 1 {
    let perturbed = Array::make(dim, 0.0)
    let factor = 0.9 + 0.2 * (m.to_double() / num_members.to_double())
    for i = 0; i < dim; i = i + 1 {
      perturbed[i] = base_arr[i] * factor
    }
    let state_m = initial_state.from_array(perturbed).unwrap()
    members[m] = state_m
  }

  { ensemble_size: num_members, states: members }
}

///|
pub fn EnsembleFilterState::assimilate_observation(
  self : EnsembleFilterState,
  var_id : String,
  obs_val : Double,
  obs_var : Double,
) -> Result[EnsembleFilterState, String] {
  let num = self.ensemble_size
  let updated_members = Array::make(num, self.states[0])

  for m = 0; m < num; m = m + 1 {
    let member_state = self.states[m]
    let model_val = match member_state.get(var_id) {
      Ok(v) => v
      Err(e) => return Err(e)
    }

    // Kalman gain K = P_xy / (P_yy + R)
    let kalman_gain = 0.5 * (1.0 / (1.0 + obs_var))
    let innovation = obs_val - model_val
    let new_val = model_val + kalman_gain * innovation

    let new_state = match member_state.set(var_id, new_val) {
      Ok(s) => s
      Err(e) => return Err(e)
    }
    updated_members[m] = new_state
  }

  Ok({ ensemble_size: num, states: updated_members })
}
