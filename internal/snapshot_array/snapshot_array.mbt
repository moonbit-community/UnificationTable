///|
pub struct SnapshotArray[T] {
  logs : @undo_logs.UndoLogs[T]
  values : Array[T]
}

///|
pub struct Snapshot {
  undo_len : Int
}

///|
/// Creates a new `SnapshotArray` with an optional initial capacity.
/// 
/// Example:
/// ```moonbit
/// let arr : SnapshotArray[Int] = SnapshotArray::new(capacity=5)
/// assert_true(arr.length() == 0)
/// ```
pub fn[T] SnapshotArray::new(capacity? : Int = 0) -> SnapshotArray[T] {
  { logs: @undo_logs.UndoLogs::new(), values: Array::new(capacity~) }
}

///|
pub fn[T] SnapshotArray::from_iter(
  iter : Iter[T],
  capacity? : Int = 0,
) -> SnapshotArray[T] {
  let arr = SnapshotArray::new(capacity~)
  arr.extend(iter)
  arr
}

///|
pub fn[T] SnapshotArray::of(values : FixedArray[T]) -> SnapshotArray[T] {
  let arr = SnapshotArray::new(capacity=values.length())
  arr.extend(values.iter())
  arr
}

///|
/// Returns the number of elements in the `SnapshotArray`.
/// 
/// Example:
/// ```moonbit
/// let arr = SnapshotArray::new(capacity=5)
/// assert_eq(arr.length(), 0)
/// arr.push(1)
/// assert_eq(arr.length(), 1)
/// ```
pub fn[T] SnapshotArray::length(self : SnapshotArray[T]) -> Int {
  self.values.length()
}

///|
/// Returns the value at the specified index
/// 
/// Example:
/// ```moonbit
/// let arr = SnapshotArray::new(capacity=5)
/// arr.push(1)
/// arr.push(2)
/// assert_eq(arr.get(0).unwrap(), 1)
/// assert_eq(arr.get(1).unwrap(), 2)
/// ```
pub fn[T] SnapshotArray::get(self : SnapshotArray[T], index : Int) -> T? {
  self.values.get(index)
}

///|
/// Revert the last action.
///
/// Example:
/// ```moonbit
/// let arr = SnapshotArray::new()
/// let snapshot = arr.start_snapshot()
/// arr.push(1)
/// arr.push(2)
/// arr.rollback_to(snapshot)
/// inspect(arr.length(), content="0")
/// ```
pub fn[T] SnapshotArray::rollback(self : SnapshotArray[T]) -> Unit {
  let undo = self.logs.pop().unwrap()
  match undo {
    NewElem(idx) => {
      let _ = self.values.pop().unwrap()
      guard idx == self.values.length() else { abort("Index mismatch") }
    }
    SetElem(idx, value) => self.values[idx] = value
  }
}

// UndoLogs

///|
/// Checks SnapshotArray for an open snapshot.
/// Returns true if there is at least one open snapshot.
///
/// Example:
///
/// ```moonbit
/// let arr : SnapshotArray[Int] = SnapshotArray::new()
/// inspect(arr.in_snapshot(), content="false")
/// let _ = arr.start_snapshot()
/// inspect(arr.in_snapshot(), content="true")
/// ```
pub fn[T] in_snapshot(self : SnapshotArray[T]) -> Bool {
  self.logs.in_snapshot()
}

///|
/// Appends an element to the end of the array. If there is an open snapshot,
/// records this operation in the undo logs.
///
/// Example:
///
/// ```moonbit
/// let arr = SnapshotArray::new()
/// let snapshot = arr.start_snapshot()
/// arr.push(1)
/// inspect(arr.length(), content="1")
/// inspect(arr.get(0).unwrap(), content="1")
/// arr.rollback_to(snapshot)
/// inspect(arr.length(), content="0")
/// ```
pub fn[T] SnapshotArray::push(self : SnapshotArray[T], elem : T) -> Unit {
  let len = self.values.length()
  self.values.push(elem)
  if self.in_snapshot() {
    self.logs.push(@undo_logs.Undo::NewElem(len))
  }
}

///|
/// Clears all elements from the snapshot array and resets it to an empty state.
/// This operation removes all stored values and clears the undo logs,
/// effectively resetting the array to its initial state.
///
/// Example:
///
/// ```moonbit
/// let arr : SnapshotArray[Int] = SnapshotArray::new()
/// arr.push(1)
/// arr.push(2)
/// inspect(arr.length(), content="2")
/// arr.reset()
/// inspect(arr.length(), content="0")
/// ```
pub fn[T] SnapshotArray::reset(self : SnapshotArray[T]) -> Unit {
  self.values.clear()
  self.logs.clear()
}

///|
/// Extends the array by appending all elements from the given iterator.
///
/// Example:
///
/// ```moonbit
/// let arr = SnapshotArray::new()
/// arr.extend([1, 2, 3].iter())
/// inspect(arr.length(), content="3")
/// inspect(arr.get(0).unwrap(), content="1")
/// ```
pub fn[T] extend(self : SnapshotArray[T], iter : Iter[T]) -> Unit {
  iter.each(fn(elem) { self.push(elem) })
}

///|
/// Sets the element at the specified index to a new value. If there is an open
/// snapshot, records this operation in the undo logs for potential rollback.
///
/// Throws an error if the index is out of bounds.
///
/// Example:
///
/// ```moonbit
/// let arr = SnapshotArray::new()
/// arr.push(1)
/// let snapshot = arr.start_snapshot()
/// arr.set(0, 42)
/// inspect(arr.get(0).unwrap(), content="42")
/// arr.rollback_to(snapshot)
/// inspect(arr.get(0).unwrap(), content="1")
/// ```
pub fn[T] set(self : SnapshotArray[T], index : Int, value : T) -> Unit {
  if index >= self.values.length() {
    abort("Index out of bounds")
  }
  let old_value = self.values[index]
  self.values[index] = value
  if self.in_snapshot() {
    self.logs.push(@undo_logs.Undo::SetElem(index, old_value))
  }
}

///|
/// Applies a transformation function to all elements in the array. If there is
/// an open snapshot, records the old values in the undo logs for potential
/// rollback.
///
/// Example:
/// ```moonbit
/// let arr = SnapshotArray::new()
/// arr.extend([1, 2, 3].iter())
/// let snapshot = arr.start_snapshot()
/// arr.set_all(fn(x) { x * 2 })
/// inspect(arr.get(0).unwrap(), content="2")
/// arr.rollback_to(snapshot)
/// inspect(arr.get(0).unwrap(), content="1")
/// ```
pub fn[T] SnapshotArray::set_all(
  self : SnapshotArray[T],
  func : (T) -> T,
) -> Unit {
  if self.in_snapshot() {
    for i in 0..<self.values.length() {
      let new_value = func(self.values[i])
      self.logs.push(@undo_logs.Undo::SetElem(i, self.values[i]))
      self.values[i] = new_value
    }
  } else {
    for i in 0..<self.values.length() {
      self.values[i] = func(self.values[i])
    }
  }
}

// Snapshot

///|
/// Creates a new snapshot of the current state of the array. The snapshot can be
/// used later to rollback changes or commit them.
///
/// Example:
///
/// ```moonbit
/// let arr = SnapshotArray::new()
/// arr.push(1)
/// let snapshot = arr.start_snapshot()
/// arr.push(2)
/// arr.rollback_to(snapshot)
/// inspect(arr.length(), content="1")
/// ```
pub fn[T] start_snapshot(self : SnapshotArray[T]) -> Snapshot {
  { undo_len: self.logs.start_snapshot() }
}

///|
/// Returns a view of all actions performed on the array since the given snapshot
/// was created.
///
/// Example:
///
/// ```moonbit
/// let arr = SnapshotArray::new()
/// let snapshot = arr.start_snapshot()
/// arr.push(1)
/// arr.push(2)
/// inspect(arr.action_since_snapshot(snapshot).length(), content="2")
/// ```
pub fn[T] SnapshotArray::action_since_snapshot(
  self : SnapshotArray[T],
  snapshot : Snapshot,
) -> ArrayView[@undo_logs.Undo[T]] {
  self.logs.action_since_snapshot(snapshot.undo_len)
}

///|
/// Reverts all changes made to the array since the given snapshot was created.
/// The changes are undone in reverse chronological order, ensuring the array
/// returns to its exact state at the time of the snapshot.
///
///
/// Example:
///
/// ```moonbit
/// let arr = SnapshotArray::new()
/// arr.push(1)
/// let snapshot = arr.start_snapshot()
/// arr.push(2)
/// arr.push(3)
/// arr.rollback_to(snapshot)
/// inspect(arr.length(), content="1")
/// inspect(arr.get(0).unwrap(), content="1")
/// ```
pub fn[T] SnapshotArray::rollback_to(
  self : SnapshotArray[T],
  snapshot : Snapshot,
) -> Unit {
  let actions = self.action_since_snapshot(snapshot)
  let count = actions.length()
  for _ in 0..<count {
    self.rollback()
  }
}

///|
/// Records a custom undo action in the snapshot logs. This allows manual
/// registration of undo operations that can be rolled back when reverting to a
/// previous snapshot.
///
/// Parameters:
///
/// * `undo` : The undo action to be recorded, which will be executed during
/// rollback operations.
///
/// Example:
///
/// ```moonbit
/// let arr : SnapshotArray[Int] = SnapshotArray::new()
/// let snapshot = arr.start_snapshot()
/// let _ = arr.record(@undo_logs.Undo::NewElem(0))
/// inspect(arr.action_since_snapshot(snapshot).length(), content="1")
/// ```
pub fn[T] SnapshotArray::record(
  self : SnapshotArray[T],
  undo : @undo_logs.Undo[T],
) -> Bool {
  if self.in_snapshot() {
    self.logs.push(undo)
    return true
  }
  false
}

///|
/// Commits all changes made since the specified snapshot, making them permanent
/// and removing the corresponding undo logs.
///
/// This operation finalizes all modifications recorded between the snapshot and
/// the current state, preventing them from being rolled back. The undo logs
/// associated with these changes are cleared, but snapshots created before the
/// committed snapshot remain valid.
///
/// Parameters:
///
/// * `snapshot` : The snapshot marking the point from which to commit all
/// subsequent changes.
///
/// Example:
///
/// ```moonbit
/// let arr = SnapshotArray::new()
/// let snapshot1 = arr.start_snapshot()
/// arr.push(1)
/// let snapshot2 = arr.start_snapshot()
/// arr.push(2)
/// arr.commit(snapshot2)
/// inspect(arr.length(), content="2")
/// // Changes after snapshot2 are committed, but can still rollback to snapshot1
/// arr.rollback_to(snapshot1)
/// inspect(arr.length(), content="0")
/// ```
pub fn[T] SnapshotArray::commit(
  self : SnapshotArray[T],
  snapshot : Snapshot,
) -> Unit {
  self.logs.commit(snapshot.undo_len)
}

///|
/// Commits all changes permanently by clearing all undo logs, making all
/// snapshots invalid.
///
/// This operation removes all recorded undo actions from the logs, effectively
/// making all changes permanent and irreversible. After calling this function,
/// any existing snapshots become invalid and cannot be used for rollback
/// operations.
///
/// Example:
///
/// ```moonbit
/// let arr = SnapshotArray::new()
/// let _snapshot = arr.start_snapshot()
/// arr.push(1)
/// arr.push(2)
/// inspect(arr.in_snapshot(), content="true")
/// arr.commit_all()
/// inspect(arr.in_snapshot(), content="false")
/// inspect(arr.length(), content="2")
/// ```
pub fn[T] SnapshotArray::commit_all(self : SnapshotArray[T]) -> Unit {
  self.logs.clear()
}

///|
pub fn[T] op_get(self : SnapshotArray[T], index : Int) -> T {
  if index < 0 || index >= self.values.length() {
    abort("Index out of bounds")
  }
  self.values[index]
}

///|
pub fn[T] op_set(self : SnapshotArray[T], index : Int, value : T) -> Unit {
  if index < 0 || index >= self.values.length() {
    abort("Index out of bounds")
  }
  self.set(index, value)
}
