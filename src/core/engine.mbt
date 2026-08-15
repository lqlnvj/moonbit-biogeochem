// Unified Box Model Engine Trait, Registry and Execution Pipeline

///|
pub(all) struct BoxModelConfig {
  name : String
  version : String
  box_volume_m3 : Double
  box_depth_m : Double
  initial_state : @types.StateVector
  parameters : @types.ParameterMap
} derive(Debug)

///|
pub fn BoxModelConfig::new(
  name : String,
  version : String,
  volume : Double,
  depth : Double,
  initial_state : @types.StateVector,
  parameters : @types.ParameterMap,
) -> BoxModelConfig {
  {
    name,
    version,
    box_volume_m3: volume,
    box_depth_m: depth,
    initial_state,
    parameters,
  }
}

///|
pub(all) struct DerivativeEvaluator {
  eval_fn : (
    Double,
    Array[Double],
    @types.EnvironmentForcing,
    @types.ParameterMap,
  ) -> Array[Double]
} derive(Debug)

///|
pub fn DerivativeEvaluator::new(
  f : (Double, Array[Double], @types.EnvironmentForcing, @types.ParameterMap) -> Array[
    Double,
  ],
) -> DerivativeEvaluator {
  { eval_fn: f }
}

///|
pub fn DerivativeEvaluator::compute(
  self : DerivativeEvaluator,
  t : Double,
  y : Array[Double],
  env : @types.EnvironmentForcing,
  params : @types.ParameterMap,
) -> Array[Double] {
  (self.eval_fn)(t, y, env, params)
}

///|
pub(all) struct BoxModel {
  config : BoxModelConfig
  current_state : @types.StateVector
  current_time : Double
  evaluator : DerivativeEvaluator
} derive(Debug)

///|
pub fn BoxModel::new(
  config : BoxModelConfig,
  evaluator : DerivativeEvaluator,
) -> BoxModel {
  { config, current_state: config.initial_state, current_time: 0.0, evaluator }
}

///|
pub fn BoxModel::get_derivatives(
  self : BoxModel,
  t : Double,
  env : @types.EnvironmentForcing,
) -> Array[Double] {
  let y = self.current_state.to_array()
  self.evaluator.compute(t, y, env, self.config.parameters)
}

///|
pub fn BoxModel::update_state(
  self : BoxModel,
  new_time : Double,
  new_vals : Array[Double],
) -> Result[BoxModel, String] {
  match self.current_state.from_array(new_vals) {
    Ok(updated_vector) =>
      Ok({
        config: self.config,
        current_state: updated_vector,
        current_time: new_time,
        evaluator: self.evaluator,
      })
    Err(err) => Err(err)
  }
}
