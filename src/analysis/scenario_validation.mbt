// Preflight validation for model configurations and numerical scenarios.

///|
pub(all) enum ValidationSeverity {
  Error
  Warning
} derive(Debug, Eq)

///|
pub(all) struct ValidationIssue {
  code : String
  severity : ValidationSeverity
  message : String
} derive(Debug)

///|
pub fn ValidationIssue::new(
  code : String,
  severity : ValidationSeverity,
  message : String,
) -> ValidationIssue {
  { code, severity, message }
}

///|
pub(all) struct ScenarioValidationReport {
  valid : Bool
  issues : Array[ValidationIssue]
} derive(Debug)

///|
fn finite_scenario_value(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
fn report_from_issues(issues : Array[ValidationIssue]) -> ScenarioValidationReport {
  let mut valid = true
  for issue in issues {
    if issue.severity is Error {
      valid = false
    }
  }
  { valid, issues }
}

///|
fn append_issues(target : Array[ValidationIssue], source : Array[ValidationIssue]) -> Unit {
  for issue in source {
    target.push(issue)
  }
}

///|
fn add_error(
  issues : Array[ValidationIssue],
  code : String,
  message : String,
) -> Unit {
  issues.push(ValidationIssue::new(code, Error, message))
}

///|
fn add_warning(
  issues : Array[ValidationIssue],
  code : String,
  message : String,
) -> Unit {
  issues.push(ValidationIssue::new(code, Warning, message))
}

///|
fn validate_state_value(
  variable : @types.StateVariable,
  index : Int,
  issues : Array[ValidationIssue],
) -> Unit {
  if variable.id == "" {
    add_error(issues, "state.empty_id", "State variable " + index.to_string() + " has an empty id")
  }
  if variable.min_val > variable.max_val {
    add_error(
      issues,
      "state.invalid_bounds",
      "State variable " + variable.id + " has min_val greater than max_val",
    )
  }
  if !finite_scenario_value(variable.value) {
    add_error(issues, "state.non_finite", "State variable " + variable.id + " is not finite")
  }
  if variable.value < variable.min_val || variable.value > variable.max_val {
    add_error(
      issues,
      "state.out_of_bounds",
      "State variable " + variable.id + " is outside its declared bounds",
    )
  }
  match variable.unit {
    @types.ConcentrationN
    | @types.ConcentrationP
    | @types.ConcentrationC
    | @types.ConcentrationO
    | @types.ConcentrationMass => {
      if variable.value < 0.0 {
        add_error(
          issues,
          "state.negative_concentration",
          "Concentration " + variable.id + " must be non-negative",
        )
      }
    }
    _ => ()
  }
}

///|
pub fn validate_state_vector(
  state : @types.StateVector,
) -> ScenarioValidationReport {
  let issues = Array::new()
  if state.vars.length() == 0 {
    add_warning(
      issues,
      "state.empty",
      "State vector has no variables",
    )
  }
  for i = 0; i < state.vars.length(); i = i + 1 {
    validate_state_value(state.vars[i], i, issues)
  }
  report_from_issues(issues)
}

///|
pub fn validate_parameter_map(
  parameters : @types.ParameterMap,
) -> ScenarioValidationReport {
  let issues = Array::new()
  for id, parameter in parameters.params {
    if id == "" || parameter.id == "" {
      add_error(issues, "parameter.empty_id", "Parameter ids must not be empty")
    }
    if parameter.min_bound > parameter.max_bound {
      add_error(
        issues,
        "parameter.invalid_bounds",
        "Parameter " + id + " has min_bound greater than max_bound",
      )
    }
    if !finite_scenario_value(parameter.value) ||
      !finite_scenario_value(parameter.min_bound) ||
      !finite_scenario_value(parameter.max_bound) {
      add_error(
        issues,
        "parameter.non_finite",
        "Parameter " + id + " contains a non-finite value",
      )
    }
    if parameter.value < parameter.min_bound || parameter.value > parameter.max_bound {
      add_error(
        issues,
        "parameter.out_of_bounds",
        "Parameter " + id + " is outside its declared bounds",
      )
    }
  }
  report_from_issues(issues)
}

///|
pub fn validate_model_scenario(
  model : @core.BoxModel,
  t_end : Double,
  dt : Double,
) -> ScenarioValidationReport {
  let issues = Array::new()
  let state_report = validate_state_vector(model.config.initial_state)
  append_issues(issues, state_report.issues)
  let parameter_report = validate_parameter_map(model.config.parameters)
  append_issues(issues, parameter_report.issues)

  if !finite_scenario_value(t_end) || t_end <= 0.0 {
    add_error(issues, "solver.invalid_end_time", "t_end must be finite and positive")
  }
  if !finite_scenario_value(dt) || dt <= 0.0 {
    add_error(issues, "solver.invalid_step", "dt must be finite and positive")
  }
  if !finite_scenario_value(model.config.box_volume_m3) ||
    model.config.box_volume_m3 <= 0.0 {
    add_error(issues, "geometry.invalid_volume", "Model volume must be finite and positive")
  }
  if !finite_scenario_value(model.config.box_depth_m) ||
    model.config.box_depth_m <= 0.0 {
    add_error(issues, "geometry.invalid_depth", "Model depth must be finite and positive")
  }

  if state_report.valid {
    let derivatives = model.get_derivatives(
      0.0, @types.EnvironmentForcing::default_surface(),
    )
    if derivatives.length() != model.config.initial_state.dimension() {
      add_error(
        issues,
        "solver.dimension_mismatch",
        "Derivative output dimension does not match the state vector",
      )
    }
  }
  if dt > t_end && t_end > 0.0 {
    add_warning(
      issues,
      "solver.coarse_step",
      "dt is larger than the requested simulation duration",
    )
  }
  report_from_issues(issues)
}
