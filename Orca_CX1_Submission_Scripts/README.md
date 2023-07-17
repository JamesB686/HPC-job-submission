# Imperial CX1 Orca PBS Submission Scripts

A set of shell scripts to configure and run parallel Orca calculations on [Imperial CX1](https://www.imperial.ac.uk/admin-services/ict/self-service/research-support/rcs/).

## Set Up Instructions

To set up a path link to the necessary executables for Orca, please use the following below instructions

1. Run the configuration shell script to set up the variables and copy the settings folder to your local directory.

``` console
~$ bash  /rds/general/user/jwb321/home/apps/Github/CX1_Orca_Submission/hpc_orca_global/config_ORCA.sh
```
(MIGHT NEED UPDATING)
2. Ensure that the settings directory has been specifed. The default location is $HOME/etc/runORCA/settings
3. The executable and MPI directories should be left to the default value (i.e. hit 'Enter') unless Orca and OpenMPI-4.1.1 code is available on your local disk.
4. To finalise the executables run the following command.

``` console
~$ source ~/.bashrc
```

## Using Parallel Orca

The parallel Orca executable, Porca, must be defined with a set of flags. The following flags are available with a * indicating that they are required.

| FLAG  | FORMAT | DEFINITION                                                               |
|:------|:------:| :------------------------------------------------------------------------|
| -in * | string | The Orca input file (a .in file).                                        |
| -nd * | int    | Number of nodes requested for the job (note 24 procs for each node)      |
| -wt * | hh:mm  | Walltime requested for the job                                           |
| -ref  | string | Reference files for the calculation. Require extension.                  |
| -set  | string | The path of settings file, developer only                                |
| -help | string | Print instructions for Porca. More detailed instructions with `HelpOrca` |

To execute the command run the following in the input file directory:

``` console
~$ Porca -in test.inp -nd 1 -wt 03:00 -ref test.gbw -ref test.bas
~$ qsub < test.qsub
```

Here a parallel Orca calculation has been called with the test.inp input file, 1 node, 3 hour walltime and the test.gbw and test.bas reference folders.
The submission file has then been submitted to the PBS queue.
