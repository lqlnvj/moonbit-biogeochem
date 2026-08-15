// Model Parameters Definition and Dictionary

///|
pub(all) struct ModelParameter {
  id : String
  name : String
  value : Double
  unit : UnitCategory
  min_bound : Double
  max_bound : Double
  description : String
} derive(Debug, Eq)

///|
pub fn ModelParameter::new(
  id : String,
  name : String,
  value : Double,
  unit : UnitCategory,
  min_bound : Double,
  max_bound : Double,
  description : String,
) -> ModelParameter {
  { id, name, value, unit, min_bound, max_bound, description }
}

///|
pub(all) struct ParameterMap {
  params : Map[String, ModelParameter]
} derive(Debug)

///|
pub fn ParameterMap::empty() -> ParameterMap {
  { params: Map::from_array([]) }
}

///|
pub fn ParameterMap::from_array(arr : Array[ModelParameter]) -> ParameterMap {
  let map : Map[String, ModelParameter] = Map::from_array([])
  for i = 0; i < arr.length(); i = i + 1 {
    map[arr[i].id] = arr[i]
  }
  { params: map }
}

///|
pub fn ParameterMap::get(
  self : ParameterMap,
  id : String,
) -> Result[Double, String] {
  match self.params.get(id) {
    Some(p) => Ok(p.value)
    None => Err("Parameter not found: " + id)
  }
}

///|
pub fn ParameterMap::set(
  self : ParameterMap,
  id : String,
  value : Double,
) -> Result[ParameterMap, String] {
  match self.params.get(id) {
    Some(p) => {
      let bounded = if value < p.min_bound {
        p.min_bound
      } else if value > p.max_bound {
        p.max_bound
      } else {
        value
      }
      let updated = ModelParameter::new(
        p.id,
        p.name,
        bounded,
        p.unit,
        p.min_bound,
        p.max_bound,
        p.description,
      )
      let new_map = self.params.copy()
      new_map[id] = updated
      Ok({ params: new_map })
    }
    None => Err("Parameter not found: " + id)
  }
}

///|
pub fn ParameterMap::keys(self : ParameterMap) -> Array[String] {
  let keys_arr = Array::new()
  self.params.each(fn(k, _) { keys_arr.push(k) })
  keys_arr
}
