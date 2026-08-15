// Sediment-Water Interface & Diagenesis Coupling

pub(all) struct SedimentBox {
  porosity : Double
  sediment_depth_cm : Double
  refractory_om : Double // mmol C / cm^3
  labile_om : Double     // mmol C / cm^3
  dissolved_nh4 : Double // mmol N / L
} derive(Debug)

pub fn SedimentBox::default() -> SedimentBox {
  {
    porosity: 0.8,
    sediment_depth_cm: 10.0,
    refractory_om: 0.5,
    labile_om: 0.1,
    dissolved_nh4: 20.0,
  }
}

pub fn SedimentBox::compute_benthic_fluxes(self : SedimentBox, temperature_c : Double) -> (Double, Double) {
  // Returns (benthic_n_remin_flux, benthic_o2_consumption_flux)
  let temp_f = @core.q10_temperature_factor(temperature_c, 15.0, 2.0)
  let k_labile = 0.05 * temp_f
  let k_refractory = 0.001 * temp_f

  let dec_labile = k_labile * self.labile_om
  let dec_refractory = k_refractory * self.refractory_om

  let n_flux = (dec_labile + dec_refractory) * (16.0 / 106.0) * self.sediment_depth_cm * 10.0
  let o2_flux = (dec_labile + dec_refractory) * (138.0 / 106.0) * self.sediment_depth_cm * 10.0

  (n_flux, o2_flux)
}
