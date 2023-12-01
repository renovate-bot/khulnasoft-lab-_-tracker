# FAQ - Frequently Asked Questions

1. Secure tracing

    When **tracker** reads information from user programs, it is subject to a
    **race condition** where the user program might be able to change the arguments
    after **tracker** read them.

    For example, a program invoked:

    ```c
    execve("/bin/ls", NULL, 0)
    ```

    Tracker picked that up and will report that, then the program changed the
    first argument from `/bin/ls` to `/bin/bash`, and this is what the kernel
    will execute.

    To mitigate this, Tracker also provides "LSM" (Linux Security Module) based
    events, for example, the `bprm_check` event which can be reported by Tracker
    and cross-referenced with the reported regular syscall event.
