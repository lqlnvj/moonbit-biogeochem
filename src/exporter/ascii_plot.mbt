// Terminal ASCII Chart & Line Plotter Renderer

///|
pub fn render_ascii_plot(
  series : Array[Double],
  title : String,
  width : Int,
  height : Int,
) -> String {
  if series.length() == 0 {
    return "Empty series"
  }

  let mut min_v = series[0]
  let mut max_v = series[0]
  for i = 1; i < series.length(); i = i + 1 {
    if series[i] < min_v {
      min_v = series[i]
    }
    if series[i] > max_v {
      max_v = series[i]
    }
  }
  let v_range = if (max_v - min_v).abs() < 1.0e-9 { 1.0 } else { max_v - min_v }

  let grid = Array::make(height, "")
  for r = 0; r < height; r = r + 1 {
    let buf = StringBuilder::new()
    let y_str = if r == 0 {
      max_v.to_string()
    } else if r == height - 1 {
      min_v.to_string()
    } else {
      "|"
    }
    buf.write_string(y_str + "\t|")

    for c = 0; c < width; c = c + 1 {
      let idx = (c.to_double() *
      (series.length() - 1).to_double() /
      width.to_double()).to_int()
      let val = series[idx]
      let normalized_r = ((max_v - val) / v_range * (height - 1).to_double()).to_int()
      if normalized_r == r {
        buf.write_string("*")
      } else {
        buf.write_string(" ")
      }
    }
    grid[r] = buf.to_string()
  }

  let res_buf = StringBuilder::new()
  res_buf.write_string("=== " + title + " ===\n")
  for r = 0; r < height; r = r + 1 {
    res_buf.write_string(grid[r] + "\n")
  }
  res_buf.write_string("-------------------------------------\n")
  res_buf.to_string()
}
