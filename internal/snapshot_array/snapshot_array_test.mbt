///|
test "SnapshotArray::new" {
  let arr = SnapshotArray::new(capacity=5)
  assert_true(arr.length() == 0)
  let _ = arr.start_snapshot()
  arr.push(1)
  assert_eq(arr.length(), 1)
  assert_eq(arr.logs.length(), 1)
}

///|
test "SnapshotArray::length" {
  let arr = SnapshotArray::new(capacity=5)
  assert_eq(arr.length(), 0)
  arr.push(1)
  assert_eq(arr.length(), 1)
}

///|
test "SnapshotArray::get" {
  let arr = SnapshotArray::new(capacity=5)
  arr.push(1)
  arr.push(2)
  assert_eq(arr.get(0).unwrap(), 1)
  assert_eq(arr.get(1).unwrap(), 2)
}

///|
test "SnapshotArray::get" {
  let arr = SnapshotArray::new(capacity=5)
  let s1 = arr.start_snapshot()
  arr.push(1)
  arr.push(2)
  assert_eq(arr.length(), 2)
  let actions = arr.action_since_snapshot(s1)
  assert_eq(actions.length(), 2)
  assert_eq(arr.get(0).unwrap(), 1)
  assert_eq(arr.get(1).unwrap(), 2)
}

///|
test "SnapshotArray::in_snapshot" {
  let arr : SnapshotArray[Int] = SnapshotArray::new()
  inspect(arr.in_snapshot(), content="false")
  let _ = arr.start_snapshot()
  inspect(arr.in_snapshot(), content="true")
}

///|
test "SnapshotArray::rollback" {
  let arr = SnapshotArray::new(capacity=5)
  let _ = arr.start_snapshot()
  arr.push(1)
  let s2 = arr.start_snapshot()
  arr.push(2)
  assert_eq(arr.length(), 2)
  arr.rollback_to(s2)
  assert_eq(arr.length(), 1)
}

///|
test "SnapshotArray::push" {
  let arr = SnapshotArray::new()
  let snapshot = arr.start_snapshot()
  arr.push(1)
  inspect(arr.length(), content="1")
  inspect(arr.get(0).unwrap(), content="1")
  arr.rollback_to(snapshot)
  inspect(arr.length(), content="0")
}

///|
test "SnapshotArray::extend" {
  let arr = SnapshotArray::new()
  arr.extend([1, 2, 3].iter())
  inspect(arr.length(), content="3")
  inspect(arr.get(0).unwrap(), content="1")
}

///|
test "SnapshotArray::set" {
  let arr = SnapshotArray::new()
  arr.push(1)
  let snapshot = arr.start_snapshot()
  arr.set(0, 42)
  inspect(arr.get(0).unwrap(), content="42")
  arr.rollback_to(snapshot)
  inspect(arr.get(0).unwrap(), content="1")
}

///|
test "SnapshotArray::set_and_get" {
  let arr = SnapshotArray::new(capacity=5)
  arr.push(1)
  arr.push(2)
  arr.set(0, 3)
  assert_eq(arr.get(0).unwrap(), 3)
  assert_eq(arr.get(1).unwrap(), 2)
  let s1 = arr.start_snapshot()
  arr.set(1, 4)
  assert_eq(arr.get(1).unwrap(), 4)
  let actions = arr.action_since_snapshot(s1)
  assert_eq(actions.length(), 1)
}

///|
test "SnapshotArray::set_all" {
  let arr = SnapshotArray::new()
  arr.extend([1, 2, 3].iter())
  let snapshot = arr.start_snapshot()
  arr.set_all(fn(x) { x * 2 })
  inspect(arr.get(0).unwrap(), content="2")
  arr.rollback_to(snapshot)
  inspect(arr.get(0).unwrap(), content="1")
}

///|
test "SnapshotArray::set_all_with_snapshot" {
  let arr = SnapshotArray::new(capacity=5)
  let _ = arr.start_snapshot()
  let s1 = arr.start_snapshot()
  arr.push(1)
  arr.push(2)
  arr.set_all(fn(i) { i + 10 })
  assert_eq(arr.get(0).unwrap(), 11)
  assert_eq(arr.get(1).unwrap(), 12)
  let s2 = arr.start_snapshot()
  arr.set_all(fn(i) { i * 2 })
  assert_eq(arr.get(0).unwrap(), 22)
  assert_eq(arr.get(1).unwrap(), 24)
  let actions = arr.action_since_snapshot(s1)
  assert_eq(actions.length(), 6)
  let actions = arr.action_since_snapshot(s2)
  assert_eq(actions.length(), 2)
}

///|
test "SnapshotArray::start_snapshot" {
  let arr = SnapshotArray::new()
  arr.push(1)
  let snapshot = arr.start_snapshot()
  arr.push(2)
  arr.rollback_to(snapshot)
  inspect(arr.length(), content="1")
}

///|
test "SnapshotArray::action_since_snapshot" {
  let arr = SnapshotArray::new()
  let snapshot = arr.start_snapshot()
  arr.push(1)
  arr.push(2)
  inspect(arr.action_since_snapshot(snapshot).length(), content="2")
}

///|
test "SnapshotArray::rollback_to" {
  let arr = SnapshotArray::new()
  arr.push(1)
  let snapshot = arr.start_snapshot()
  arr.push(2)
  arr.push(3)
  arr.rollback_to(snapshot)
  inspect(arr.length(), content="1")
  inspect(arr.get(0).unwrap(), content="1")
}
