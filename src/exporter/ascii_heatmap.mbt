// Terminal ASCII Heatmap & Matrix Density Visualizer

///|
pub fn render_ascii_heatmap(
  matrix : Array[Array[Double]],
  title : String,
) -> String {
  let rows = matrix.length()
  if rows == 0 {
    return "Empty Matrix"
  }
  let cols = matrix[0].length()
  let buf = StringBuilder::new()
  buf.write_string("=== ASCII Heatmap: " + title + " ===\n")

  for r = 0; r < rows; r = r + 1 {
    buf.write_string("Row " + r.to_string() + ": |")
    for c = 0; c < cols; c = c + 1 {
      let val = matrix[r][c]
      let symbol = if val < 0.2 {
        "."
      } else if val < 0.5 {
        "+"
      } else if val < 0.8 {
        "*"
      } else {
        "#"
      }
      buf.write_string(symbol)
    }
    buf.write_string("|\n")
  }
  buf.to_string()
}
