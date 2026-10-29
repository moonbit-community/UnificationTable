///|
pub extend UnificationTable with Show::{to_string, output}

///|
pub extend VarIndex with Show::{to_string, output}

///|
pub extend VarValue with Eq::{not_equal, equal}

///|
pub extend VarValue with Show::{to_string, output}
