module sitrep.util.thread;

import core.thread : Thread;

/// Spawn a thread. The thread will run the given function.
@system
void spawn(void delegate() dg)
{
    auto thread = new Thread(dg);
    thread.start();
}
