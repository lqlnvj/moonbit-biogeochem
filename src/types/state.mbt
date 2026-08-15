// State Variables, Vectors and Bounds Representation

///|
pub(all) struct StateVariable {
  id : String
  name : String
  unit : UnitCategory
  value : Double
  min_val : Double
  max_val : Double
} derive(Debug, Eq)

///|
pub fn StateVariable::new(
  id : String,
  name : String,
  unit : UnitCategory,
  initial_value : Double,
  min_val : Double,
  max_val : Double,
) -> StateVariable {
  let bounded_val = if initial_value < min_val {
    min_val
  } else if initial_value > max_val {
    max_val
  } else {
    initial_value
  }
  { id, name, unit, value: bounded_val, min_val, max_val }
}

///|
pub fn StateVariable::clamp(self : StateVariable) -> StateVariable {
  let v = if self.value < self.min_val {
    self.min_val
  } else if self.value > self.max_val {
    self.max_val
  } else {
    self.value
  }
  {
    id: self.id,
    name: self.name,
    unit: self.unit,
    value: v,
    min_val: self.min_val,
    max_val: self.max_val,
  }
}

///|
pub(all) struct StateVector {
  vars : Array[StateVariable]
  indices : Map[String, Int]
} derive(Debug)

///|
pub fn StateVector::new(vars : Array[StateVariable]) -> StateVector {
  let indices : Map[String, Int] = Map::from_array([])
  for i = 0; i < vars.length(); i = i + 1 {
    indices[vars[i].id] = i
  }
  { vars, indices }
}

///|
pub fn StateVector::get(
  self : StateVector,
  id : String,
) -> Result[Double, String] {
  match self.indices.get(id) {
    Some(idx) => Ok(self.vars[idx].value)
    None => Err("StateVariable not found: " + id)
  }
}

///|
pub fn StateVector::set(
  self : StateVector,
  id : String,
  val : Double,
) -> Result[StateVector, String] {
  match self.indices.get(id) {
    Some(idx) => {
      let new_vars = self.vars.copy()
      let old_var = new_vars[idx]
      let updated_var = StateVariable::new(
        old_var.id,
        old_var.name,
        old_var.unit,
        val,
        old_var.min_val,
        old_var.max_val,
      ).clamp()
      new_vars[idx] = updated_var
      Ok({ vars: new_vars, indices: self.indices })
    }
    None => Err("StateVariable not found: " + id)
  }
}

///|
pub fn StateVector::to_array(self : StateVector) -> Array[Double] {
  let arr = Array::make(self.vars.length(), 0.0)
  for i = 0; i < self.vars.length(); i = i + 1 {
    arr[i] = self.vars[i].value
  }
  arr
}

///|
pub fn StateVector::from_array(
  self : StateVector,
  vals : Array[Double],
) -> Result[StateVector, String] {
  if vals.length() != self.vars.length() {
    return Err("Array length mismatch for StateVector update")
  }
  let new_vars = Array::make(self.vars.length(), self.vars[0])
  for i = 0; i < self.vars.length(); i = i + 1 {
    let old_var = self.vars[i]
    new_vars[i] = StateVariable::new(
      old_var.id,
      old_var.name,
      old_var.unit,
      vals[i],
      old_var.min_val,
      old_var.max_val,
    ).clamp()
  }
  Ok({ vars: new_vars, indices: self.indices })
}

///|
pub fn StateVector::dimension(self : StateVector) -> Int {
  self.vars.length()
}

///|
pub fn StateVector::names(self : StateVector) -> Array[String] {
  let res = Array::make(self.vars.length(), "")
  for i = 0; i < self.vars.length(); i = i + 1 {
    res[i] = self.vars[i].id
  }
  res
}
