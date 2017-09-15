# mpiGraph
Benchmark to generate network bandwidth images

## Build 
    make

## Run
Run one MPI task per node:

    SLURM: srun -n <nodes> -N #nodes> ./mpiGraph 1048576 10 10 > mpiGraph.out
    Open MPI: mpirun --map-by node -np <nodes> ./mpiGraph 1048576 10 10 > mpiGraph.out

General usage:

    mpiGraph <size> <iters> <window>

To compute bandwidth, each task averages the bandwidth from *iters* iterations.
In each iteration, a process sends *window* number of messages of size *size* bytes to another process
while it simultaneously receives an equal number of messages of equal size from another process.
The source and destination processes in each step are not necessary the same process.

Watch progress:

    tail -f mpiGraph.out

## Results
Parse output and create html report:

    crunch_mpiGraph mpiGraph.out

View results in a web browser:

    firefox file:///path/to/mpiGraph.out_html/index.html

# Description

This package consists of an MPI application called "mpiGraph" written in C
to measure message bandwidth and an associated "crunch_mpigraph"
script written in Perl to parse the application output a generate an HTML
report.  The mpiGraph application is designed to inspect the health
and scalability of a high-performance interconnect while subjecting it
to heavy load.  This is useful to detect hardware and software
problems in a system, such as slow nodes, links, switches, or
contention in switch routing.  It is also useful to characterize how
interconnect performance changes with different settings or how one
interconnect type compares to another.

Typically, one MPI task is run per node (or per interconnect link).
For a job of N MPI tasks, the N tasks are logically arranged in a ring
counting ranks from 0 and increasing to the right with the end
wrapping back to rank 0.  Then a series of N-1 steps are executed.
In each step, each MPI task sends to the task D units to the right and
simultaneously receives from the task D units to the left.  The value
of D starts at 1 and runs to N-1, so that by the end of the N-1 steps,
each task has sent to and received from every other task in the run,
excluding itself.  At the end of the run, two NxN matrices of
bandwidths are gathered and written to stdout -- one for send
bandwidths and one for receive bandwidths.

The crunch_mpiGraph script is then run on this output to generate a
report.  It includes a pair of bitmap images
representing bandwidth values between different task pairings.
Pixels in this image are colored depending on relative bandwidth
values.  The maximum bandwidth value is set to pure white (value
255) and other values are scaled to black (0) depending on their
percentage of the maximum.  One can then visually inspect and identify anomalous
behavior in the system.  One may zoom in and inspect image
features in more detail by hovering the mouse cursor over the image.
Javascript embedded in the HTML report opens a pop-up tooltip with a
zoomed-in view of the cursor location.

## References
[Contention-free Routing for Shift-based Communication in MPI Applications on Large-scale Infiniband Clusters](https://e-reports-ext.llnl.gov/pdf/380228.pdf), Adam Moody, LLNL-TR-418522, Oct 2009
