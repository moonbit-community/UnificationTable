///|
test "UnificationTable::push" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
  table.push(1)
  assert_true(table.values.length() == 1)
}

///|
test "UnificationTable::new" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=10)
  inspect(table.values.length(), content="0")
}

///|
test "UnificationTable::push_var" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
  let var_value = VarValue::new(42, 0, VarIndex::new(0))
  table.push_var(var_value)
  inspect(table.values.length(), content="1")
}

///|
test "UnificationTable::get" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
  table.push(42)
  inspect(
    table.get(0),
    content="Some(VarValue { value: 42, rank: 0, parent: VarIndex { index: 0 } })",
  )
  inspect(table.get(1), content="None")
}

///|
test "UnificationTable::index" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
  table.push(42)
  inspect(table.index(0).index, content="0")
}

///|
test "panic UnificationTable::index/out_of_bounds" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
  let _ = table.index(-1)

}

///|
test "UnificationTable::value" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
  table.push(42)
  let index = VarIndex::new(0)
  inspect(
    table.value(index),
    content="VarValue { value: 42, rank: 0, parent: VarIndex { index: 0 } }",
  )
}

///|
test "UnificationTable::union_test" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
  for i in 0..<5 {
    table.push(i)
  }
  let index1 = table.index(1)
  let index2 = table.index(2)
  let index3 = table.index(3)
  assert_false(table.unioned(index1, index2))
  let _ = table.unite(index1, index2, 8)
  assert_true(table.unioned(index1, index2))
  assert_false(table.unioned(index1, index3))
  assert_true(table.unioned(index2, index1))
  assert_false(table.unioned(index2, index3))
}

///|
test "UnificationTable::reset" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=2)
  table.push(1)
  table.push(2)
  let _ = table.unite(VarIndex::new(0), VarIndex::new(1), 42)
  table.reset()
  inspect(table.unioned(VarIndex::new(0), VarIndex::new(1)), content="false")
}

///|
test "UnificationTable::set" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
  table.push(42)
  let new_value = VarValue::new(100, 0, VarIndex::new(0))
  table.set(VarIndex::new(0), new_value)
  inspect(
    table.get(0),
    content="Some(VarValue { value: 100, rank: 0, parent: VarIndex { index: 0 } })",
  )
}

///|
test "UnificationTable::update" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
  table.push(42)
  table.update(VarIndex::new(0), fn(val) { val.root(val.rank, 100) })
  inspect(
    table.get(0),
    content="Some(VarValue { value: 100, rank: 0, parent: VarIndex { index: 0 } })",
  )
}

///|
test "UnificationTable::redirect_root" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=2)
  table.push(1)
  table.push(2)
  table.redirect_root(1, VarIndex::new(0), VarIndex::new(1), 42)
  inspect(table.find(VarIndex::new(0)).index, content="1")
}

///|
test "UnificationTable::unioned" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=2)
  table.push(1)
  table.push(2)
  let _ = table.unite(table.index(0), table.index(1), 42)
  inspect(table.unioned(VarIndex::new(0), VarIndex::new(1)), content="true")
}

///|
test "UnificationTable::unite" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=2)
  table.push(1)
  table.push(2)
  let root = table.unite(table.index(0), table.index(1), 42)
  inspect(table.value(root).value, content="42")
}

///|
test "UnificationTable::find" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=3)
  table.push(1)
  table.push(2)
  table.push(3)
  let _ = table.unite(table.index(0), table.index(1), 42)
  let root = table.find(table.index(0))
  inspect(root.index, content="0")
}

///|
test "UnificationTable::find_2" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
  for i in 0..<5 {
    table.push(i)
  }
  let index1 = table.index(1)
  let index2 = table.index(2)
  let index3 = table.index(3)
  let _ = table.unite(index1, index2, 8)
  assert_eq(table.value(index1).value, 8)
  let _ = table.unite(index3, index1, 9)
  assert_eq(table.value(index1).value, 9)
  // for i in 0..<5 {
  //   println(table.get(i))
  // }
  // println(table.find(index2))
}

///|
test "UnificationTable::find_root" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=2)
  table.push(1)
  table.push(2)
  let _ = table.unite(table.index(0), table.index(1), 42)
  let value = table.get(0).unwrap()
  let root = table.find_root(value)
  inspect(root.value, content="42")
}

///|
test "UnificationTable::in_snapshot" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
  let _ = table.start_snapshot()
  assert_true(table.in_snapshot())
}

///|
test "UnificationTable::start_snapshot/rollback_to" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
  table.push(42)
  let snapshot = table.start_snapshot()
  table.push(100)
  table.rollback_to(snapshot)
  inspect(table.values.length(), content="1")
}

///|
test "UnificationTable::commit" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
  table.push(42)
  let snapshot = table.start_snapshot()
  table.push(100)
  table.commit(snapshot)
  inspect(table.values.length(), content="2")
}

///|
test "VarValue::new" {
  let index = VarIndex::new(0)
  let var_value = VarValue::new(42, 0, index)
  inspect(var_value.value, content="42")
  inspect(var_value.rank, content="0")
  inspect(var_value.parent.index, content="0")
}

///|
test "VarValue::redirect" {
  let old_parent = VarIndex::new(0)
  let new_parent = VarIndex::new(1)
  let var_value = VarValue::new(42, 0, old_parent)
  let var_value = var_value.redirect(new_parent)
  inspect(var_value.parent.index, content="1")
}

///|
test "VarValue::root" {
  let index = VarIndex::new(0)
  let var_value = VarValue::new(42, 0, index)
  let var_value = var_value.root(1, 100)
  inspect(var_value.value, content="100")
  inspect(var_value.rank, content="1")
}

///|
test "VarValue::modify" {
  let index = VarIndex::new(0)
  let var_value = VarValue::new(42, 0, index)
  var_value.modify(100)
  inspect(var_value.value, content="100")
}

///|
test "UnificationTable::snapshot_unite_test" {
  let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
  let _ = table.start_snapshot()
  for i in 0..<5 {
    table.push(i)
  }
  let s1 = table.start_snapshot()
  let index1 = table.index(1)
  let index2 = table.index(2)
  let index3 = table.index(3)
  assert_false(table.unioned(index1, index2))
  let _ = table.unite(index1, index2, 8)
  assert_true(table.unioned(index1, index2))
  assert_false(table.unioned(index1, index3))
  assert_false(table.unioned(index2, index3))
  table.rollback_to(s1)
  assert_false(table.unioned(index1, index2))
  assert_false(table.unioned(index1, index3))
  assert_false(table.unioned(index2, index1))
}
