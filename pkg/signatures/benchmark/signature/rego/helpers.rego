package tracker.helpers

get_tracker_argument(arg_name) = res {
    arg := input.args[_]
    arg.name == arg_name
    res := arg.value
}


default is_file_write(flags) = false
is_file_write(flags) {
    contains(lower(flags), "o_wronly")
}
is_file_write(flags) {
    contains(lower(flags), "o_rdwr")
}