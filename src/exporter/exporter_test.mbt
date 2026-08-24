// Unit tests for src/exporter module

///|
test "csv trajectory export" {
  let traj = @solver.Trajectory::new(["N", "P"])
  traj.append(0.0, [10.0, 0.5], 0.1)
  traj.append(1.0, [9.0, 1.2], 0.1)
  let csv = export_trajectory_csv(traj)
  assert_true(csv.contains("time_day,N,P"))
  assert_true(csv.contains("0,10,0.5"))
}

///|
test "ascii plotter rendering" {
  let series = [1.0, 2.0, 5.0, 3.0, 1.5]
  let plot = render_ascii_plot(series, "Test Plot", 10, 4)
  assert_true(plot.contains("Test Plot"))
}

///|
test "mermaid diagram export" {
  let diagram = export_mermaid_diagram("NPZD", ["N", "P", "Z", "D"])
  assert_true(diagram.contains("flowchart TD"))
  assert_true(diagram.contains("N -->|Primary Production| P"))
}

///|
fn create_export_test_model() -> @core.BoxModel {
  let variable = @types.StateVariable::new(
    "N",
    "Nutrient",
    @types.ConcentrationN,
    4.0,
    0.0,
    20.0,
  )
  let state = @types.StateVector::new([variable])
  let parameter = @types.ModelParameter::new(
    "k",
    "Decay Rate",
    0.1,
    @types.RatePerDay,
    0.0,
    1.0,
    "test decay rate",
  )
  let params = @types.ParameterMap::from_array([parameter])
  let config = @core.BoxModelConfig::new(
    "ExportFixture", "1.0", 1000.0, 10.0, state, params,
  )
  let evaluator = @core.DerivativeEvaluator::new(fn(_t, y, _env, p) {
    let k = p.get("k").unwrap()
    [-k * y[0]]
  })
  @core.BoxModel::new(config, evaluator)
}

///|
test "heatmap renders threshold symbols and empty matrices" {
  let heatmap = render_ascii_heatmap([[0.1, 0.3, 0.6, 0.9]], "Nutrients")
  assert_true(heatmap.contains("=== ASCII Heatmap: Nutrients ==="))
  assert_true(heatmap.contains(".+*#|"))
  assert_eq(render_ascii_heatmap([], "Empty"), "Empty Matrix")
}

///|
test "json and markdown exporters include model state" {
  let model = create_export_test_model()
  let json = export_model_config_json(model)
  assert_true(json.contains("\"name\": \"ExportFixture\""))
  assert_true(json.contains("\"id\": \"N\""))

  let report = generate_markdown_report(
    "ExportFixture",
    3.0,
    model.current_state,
    "CONSERVED",
  )
  assert_true(
    report.contains("# Ocean Biogeochemical Box Model Simulation Report"),
  )
  assert_true(report.contains("| `N` | Nutrient | 4 |"))
}

///|
test "junit exporter produces a ci-compatible summary" {
  let report = export_junit_xml_report("biogeochem", 12, 1)
  assert_true(
    report.contains(
      "<testsuite name=\"biogeochem\" tests=\"12\" failures=\"1\">",
    ),
  )
  assert_true(report.contains("Mass_Conservation_Audit"))
}

///|
test "mermaid exporter omits unavailable compartment links" {
  let diagram = export_mermaid_diagram("Nutrient", ["N", "P"])
  assert_true(diagram.contains("N -->|Primary Production| P"))
  assert_true(diagram.contains("P -->|Grazing| Z") == false)
  let empty = export_mermaid_diagram("Empty", [])
  assert_true(empty.contains("Primary Production") == false)
}
