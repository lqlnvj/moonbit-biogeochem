// Parameter Grid Sweep & Sampling Analysis Framework

pub(all) struct ParameterRange {
  param_id : String
  min_val : Double
  max_val : Double
  steps : Int
} derive(Debug)

pub fn ParameterRange::new(id : String, min_v : Double, max_v : Double, steps : Int) -> ParameterRange {
  { param_id: id, min_val: min_v, max_val: max_v, steps }
}

pub fn ParameterRange::generate_grid(self : ParameterRange) -> Array[Double] {
  if self.steps <= 1 {
    [ self.min_val ]
  } else {
    let arr = Array::make(self.steps, 0.0)
    let step_size = (self.max_val - self.min_val) / (self.steps - 1).to_double()
    for i = 0; i < self.steps; i = i + 1 {
      arr[i] = self.min_val + i.to_double() * step_size
    }
    arr
  }
}

pub(all) struct SweepResultPoint {
  param_values : Map[String, Double]
  final_state : Array[Double]
  max_phyto : Double
} derive(Debug)

pub fn run_1d_parameter_sweep(
  model_factory : (@types.ParameterMap) -> @core.BoxModel,
  base_params : @types.ParameterMap,
  param_range : ParameterRange,
  t_end : Double,
  dt : Double,
  target_var : String
) -> Result[Array[SweepResultPoint], String] {
  let values = param_range.generate_grid()
  let results = Array::new()

  for i = 0; i < values.length(); i = i + 1 {
    let v = values[i]
    let updated_params = match base_params.set(param_range.param_id, v) {
      Ok(p) => p
      Err(e) => return Err(e)
    }
    let model = model_factory(updated_params)
    let env_fn = fn(t) { @types.EnvironmentForcing::seasonal_forcing(t, 45.0) }
    let traj = match @solver.solve_rk4(model, t_end, dt, env_fn) {
      Ok(tr) => tr
      Err(e) => return Err(e)
    }

    let series = match traj.get_time_series(target_var) {
      Ok(s) => s
      Err(e) => return Err(e)
    }
    let mut max_val = 0.0
    for j = 0; j < series.length(); j = j + 1 {
      if series[j] > max_val {
        max_val = series[j]
      }
    }

    let p_map : Map[String, Double] = Map::from_array([])
    p_map[param_range.param_id] = v

    let final_pts = traj.points[traj.points.length() - 1].values
    results.push({
      param_values: p_map,
      final_state: final_pts,
      max_phyto: max_val,
    })
  }

  Ok(results)
}
