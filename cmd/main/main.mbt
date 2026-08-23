// MoonBit Marine Biogeochemical Box Model Engine Entrypoint & Demo

///|
fn main {
  println(
    "================================================================================",
  )
  println(
    "  MoonBit Marine Biogeochemical Box Model Engine (`moonbit-biogeochem`) v0.1.1  ",
  )
  println(
    "================================================================================\n",
  )

  // Demo 1: Run 4-Compartment NPZD Ecosystem Simulation using Classic RK4
  println("[1] Running NPZD Seawater Box Ecosystem Simulation (RK4 Solver)...")
  let npzd_model = @models.create_npzd_model(15.0, 0.5, 0.1, 0.2)
  let env_fn = fn(t) { @types.EnvironmentForcing::seasonal_forcing(t, 45.0) }
  match @solver.solve_rk4(npzd_model, 30.0, 0.5, env_fn) {
    Ok(traj) => {
      println(
        "  -> Completed " +
        traj.length().to_string() +
        " simulation time steps successfully.",
      )
      let p_series = traj.get_time_series("P").unwrap()
      let plot = @exporter.render_ascii_plot(
        p_series, "Phytoplankton Concentration (mmol N/m^3)", 30, 6,
      )
      println("\n" + plot)

      let diag = @analysis.diagnose_npzd_trajectory(traj).unwrap()
      println("  Mass Balance Status: " + diag.mass_conservation_status)
      if diag.mass_conservation_status == "OPEN_SYSTEM_EXPORT" {
        println(
          "  Note: Detritus sinking is modeled as an expected export from the box.",
        )
      }
      println(
        "  Initial Mass: " +
        diag.initial_total_mass.to_string() +
        " | Final Mass: " +
        diag.final_total_mass.to_string(),
      )
    }
    Err(err) => println("  Error running NPZD simulation: " + err)
  }

  // Demo 2: Run Coupled NPZD-O2-Carbonate System using Adaptive RKF45 Solver
  println(
    "\n[2] Running Fully Coupled NPZD - Ocean Carbonate & Hypoxia Box Model (RK45 Adaptive Solver)...",
  )
  let coupled_model = @models.create_coupled_carbon_npzd_model(
    12.0, 0.8, 0.2, 0.1, 240.0, 2100.0, 2300.0,
  )
  let cfg = @solver.AdaptiveSolverConfig::default()
  match @solver.solve_rk45(coupled_model, 20.0, 0.5, cfg, env_fn) {
    Ok(traj) => {
      println(
        "  -> Adaptive solver steps executed: " + traj.length().to_string(),
      )
      let _dic_series = traj.get_time_series("DIC").unwrap()
      let csv = @exporter.export_trajectory_csv(traj)
      let preview_len = if csv.length() < 70 { csv.length() } else { 70 }
      println(
        "  -> Trajectory CSV preview (first header line):\n  " +
        csv[0:preview_len].to_owned() +
        "...\n",
      )
    }
    Err(err) => println("  Error running coupled simulation: " + err)
  }

  // Demo 3: Sensitivity Analysis on Max Phytoplankton Growth Rate
  println("[3] Performing Local Sensitivity Analysis (Delta = 5%)...")
  let npzd_base = @models.create_npzd_model(15.0, 0.5, 0.1, 0.2)
  match
    @analysis.compute_local_sensitivity(
      fn(p) { @models.create_npzd_model_with_params(p) },
      npzd_base.config.parameters,
      "v_max",
      "P",
      0.05,
      10.0,
    ) {
    Ok(sens) => {
      println("  Parameter: " + sens.param_id + " -> Target: " + sens.var_id)
      println(
        "  Normalized Sensitivity Coefficient: " +
        sens.normalized_sensitivity.to_string(),
      )
    }
    Err(err) => println("  Sensitivity calculation note: " + err)
  }

  // Demo 4: 1D Vertical Water Column Extension & Sediment Coupling
  println(
    "\n[4] Initializing 1D Vertical Water Column Grid & Sediment Coupling...",
  )
  let col = @extensions.WaterColumn1D::create(5, 50.0, [15.0, 0.5])
  let diff = col.compute_vertical_diffusion(0)
  println(
    "  -> 5-Layer Vertical Diffusion Term array initialized: " +
    diff.length().to_string() +
    " layers computed.",
  )
  let sed = @extensions.SedimentBox::default()
  let (n_flux, o2_flux) = sed.compute_benthic_fluxes(18.0)
  println(
    "  -> Sediment Benthic Return Flux: " +
    n_flux.to_string() +
    " mmol N/m^2/day | O2 Demand: " +
    o2_flux.to_string() +
    " mmol O2/m^2/day",
  )

  // Demo 5: Mermaid Flow Topology Diagram Export
  println("\n[5] Exporting Model Architecture Mermaid Diagram...")
  let diagram = @exporter.export_mermaid_diagram("NPZD", ["N", "P", "Z", "D"])
  println(diagram)

  println(
    "All biogeochemical engine demonstration tasks completed successfully.",
  )
}
