// Declarative Model DSL Builder

///|
pub(all) struct ModelBuilder {
  name : String
  vars : Array[@types.StateVariable]
  params : Array[@types.ModelParameter]
  depth_m : Double
  volume_m3 : Double
} derive(Debug)

///|
pub fn ModelBuilder::create(name : String) -> ModelBuilder {
  {
    name,
    vars: Array::new(),
    params: Array::new(),
    depth_m: 50.0,
    volume_m3: 1.0e6,
  }
}

///|
pub fn ModelBuilder::add_variable(
  self : ModelBuilder,
  state_var : @types.StateVariable,
) -> ModelBuilder {
  self.vars.push(state_var)
  self
}

///|
pub fn ModelBuilder::add_parameter(
  self : ModelBuilder,
  param : @types.ModelParameter,
) -> ModelBuilder {
  self.params.push(param)
  self
}

///|
pub fn ModelBuilder::set_geometry(
  self : ModelBuilder,
  depth : Double,
  volume : Double,
) -> ModelBuilder {
  {
    name: self.name,
    vars: self.vars,
    params: self.params,
    depth_m: depth,
    volume_m3: volume,
  }
}

///|
pub fn ModelBuilder::build(
  self : ModelBuilder,
  eval_fn : (
    Double,
    Array[Double],
    @types.EnvironmentForcing,
    @types.ParameterMap,
  ) -> Array[Double],
) -> @core.BoxModel {
  let state = @types.StateVector::new(self.vars)
  let p_map = @types.ParameterMap::from_array(self.params)
  let config = @core.BoxModelConfig::new(
    self.name,
    "1.0.0",
    self.volume_m3,
    self.depth_m,
    state,
    p_map,
  )
  let evaluator = @core.DerivativeEvaluator::new(eval_fn)
  @core.BoxModel::new(config, evaluator)
}
