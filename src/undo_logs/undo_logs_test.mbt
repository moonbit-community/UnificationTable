///|
test "UndoLogs::new" {
  let logs = @undo_logs.new()
  logs.push(@undo_logs.newElem(0))
  logs.push(@undo_logs.setElem(1, "test"))
}

///|
test "UndoLogs::in_snapshot" {
  let logs = @undo_logs.new()
  logs.push(@undo_logs.newElem(0))
  logs.push(@undo_logs.setElem(1, "test"))
  assert_false(logs.in_snapshot())
  let _ = logs.start_snapshot()
  assert_true(logs.in_snapshot())
}

///|
test "UndoLogs::length" {
  let logs = @undo_logs.new()
  logs.push(@undo_logs.newElem(0))
  logs.push(@undo_logs.setElem(1, "test"))
  assert_eq(logs.length(), 2)
}

///|
test "UndoLogs::num_open_snapshots_nested" {
  let logs = @undo_logs.new()
  let _ = logs.start_snapshot()
  assert_true(logs.num_open_snapshots() == 1)
  logs.push(@undo_logs.newElem(0))
  let s1 = logs.start_snapshot()
  logs.push(@undo_logs.setElem(1, "test"))
  logs.commit(s1)
}

///|
test "UndoLogs::push" {
  let logs = @undo_logs.new()
  logs.push(@undo_logs.newElem(0))
  logs.push(@undo_logs.setElem(1, "test"))
  assert_eq(logs.length(), 2)
}

///|
test "UndoLogs::clear" {
  let logs = @undo_logs.new()
  let _ = logs.start_snapshot()
  logs.push(@undo_logs.newElem(0))
  let _ = logs.start_snapshot()
  logs.push(@undo_logs.setElem(1, "test"))
  logs.clear()
  assert_true(logs.logs.length() == 0)
  assert_true(logs.num_open_snapshots == 0)
}

///|
test "UndoLogs::extend" {
  let logs = @undo_logs.new()
  let new_logs = [@undo_logs.newElem(0), @undo_logs.setElem(1, "test")]
  logs.append_iter(new_logs.iter())
  assert_true(logs.logs.length() == 2)
  inspect(logs.logs[0], content="NewElem(0)")
  inspect(logs.logs[1], content="SetElem(1, test)")
}

///|
test "UndoLogs::num_open_snapshots" {
  let logs = @undo_logs.new()
  let s1 = logs.start_snapshot()
  assert_true(logs.num_open_snapshots() == 1)
  logs.push(@undo_logs.newElem(0))
  let s2 = logs.start_snapshot()
  logs.push(@undo_logs.setElem(1, "test"))
  logs.commit(s2)
  logs.commit(s1)
}

///|
test "UndoLogs::action_since_snapshot" {
  let logs = @undo_logs.new()
  let s1 = logs.start_snapshot()
  logs.push(@undo_logs.newElem(0))
  logs.push(@undo_logs.setElem(1, "test"))
  let actions = logs.action_since_snapshot(s1)
  assert_eq(actions.length(), 2)
  inspect(actions[0], content="NewElem(0)")
  inspect(actions[1], content="SetElem(1, test)")
}

///|
test "UndoLogs::has_changes" {
  let logs = @undo_logs.new()
  let s1 = logs.start_snapshot()
  assert_false(logs.has_changes(s1))
  logs.push(@undo_logs.setElem(2, "another_test"))
  assert_true(logs.has_changes(s1))
}

///|
test "UndoLogs::start_snapshot" {
  let logs = @undo_logs.new()
  let s1 = logs.start_snapshot()
  logs.push(@undo_logs.newElem(0))
  logs.push(@undo_logs.setElem(1, "test"))
  debug_inspect(
    logs.action_since_snapshot(s1),
    content="<ArrayView: [NewElem(0), SetElem(1, \"test\")]>",
  )
}

///|
test "UndoLogs::rollback_to" {
  let logs = @undo_logs.new()
  let _ = logs.start_snapshot()
  logs.push(@undo_logs.newElem(0))
  logs.push(@undo_logs.setElem(1, "test"))
  let _ = logs.start_snapshot()
  logs.push(@undo_logs.setElem(2, "rollback_test"))
  let s3 = logs.start_snapshot()
  logs.push(@undo_logs.setElem(3, "another_rollback_test"))
  logs.push(@undo_logs.newElem(4))
  debug_inspect(
    logs.rollback_to(s3),
    content="[SetElem(3, \"another_rollback_test\"), NewElem(4)]",
  )
}

///|
test "UndoLogs::pop" {
  let logs = @undo_logs.new()
  logs.push(@undo_logs.newElem(0))
  logs.push(@undo_logs.setElem(1, "test"))
  let popped = logs.pop().unwrap()
  assert_eq(popped, @undo_logs.setElem(1, "test"))
  assert_eq(logs.length(), 1)
}

///|
test "UndoLogs::last" {
  let logs = @undo_logs.new()
  logs.push(@undo_logs.newElem(0))
  logs.push(@undo_logs.setElem(1, "test"))
  let last = logs.last().unwrap()
  assert_eq(last, @undo_logs.setElem(1, "test"))
}

///|
test "UndoLogs::commit" {
  let logs = @undo_logs.new()
  let s1 = logs.start_snapshot()
  logs.push(@undo_logs.newElem(0))
  logs.push(@undo_logs.setElem(1, "test"))
  logs.commit(s1)
  assert_eq(logs.length(), 0)
}
