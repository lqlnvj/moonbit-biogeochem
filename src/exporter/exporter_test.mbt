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
