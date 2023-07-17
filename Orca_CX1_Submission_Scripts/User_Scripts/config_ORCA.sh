#!/bin/bash
function welcome_msg_ {
    cat << EOF
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
                            ORCA JOB SUBMISSION SCRIPT
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
ORCA job submission script for Imperial HPC - Setting up

Job submission script installed date : `date`
Batch system                         : PBS
Program                              : Orca 
Version                              : 5.0.4
MPI Version                          : 4.1.1
Author(s)                            : James Broadhurst (ICL), Huanyu Zhou (ICL)
--------------------------------------------------------------------------------
ACKNOWLEDGMENTS:

    Many thanks to Huanyu Zhou (ICL) for providing the original submission 
    scripts from which this script was adapted from.

EOF
}


function get_scriptdir_ {

    cat << EOF
================================================================================
                                INSTALLATION DIRECTORY
================================================================================
    Please specify your installation path (leave blank for default option).

    Default Option:

        ${HOME}/etc/runORCA

EOF


    read -p "    User Option: " SCRIPTDIR

    if [[ -z ${SCRIPTDIR} ]]; then

        SCRIPTDIR=${HOME}/etc/runORCA

    fi

    if [[ ${SCRIPTDIR: -1} == '/' ]]; then
        SCRIPTDIR=${SCRIPTDIR%/*}
    fi

    SCRIPTDIR=`realpath $(echo ${SCRIPTDIR}) 2>&1 | sed -r 's/.*\:(.*)\:.*/\1/' | sed 's/[[:space:]]//g'`
    source_dir=`realpath $(dirname $0)`
    if [[ ${source_dir} == ${SCRIPTDIR} ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    ERROR: You cannot specify the source directory as your settings directory.
    Your option: ${SCRIPTDIR}

--------------------------------------------------------------------------------
                                    EXITING NOW
--------------------------------------------------------------------------------
EOF
        exit
    else
        ls ${SCRIPTDIR} > /dev/null 2>&1
        if [[ $? == 0 ]]; then
            cat << EOF
--------------------------------------------------------------------------------
    WARNING: Directory exists - current folder will be removed and replaced
    with new directory.

EOF
            rm -r ${SCRIPTDIR}
        fi
    fi
}

function set_exe_ {

    cat << EOF
================================================================================
                                EXECUTABLES DIRECTORY
================================================================================
    Please specify the directory of OCRA executables (leave blank for default
    option).

    Default Option:

        /rds/general/user/jwb321/home/app/orca/orca_files

EOF

    
    read -p "   User Option: " EXEDIR
    EXEDIR=`echo ${EXEDIR}`

    if [[ -z ${EXEDIR} ]]; then

        EXEDIR='/rds/general/user/jwb321/home/apps/orca/orca_files'

    fi

    if [[ ! -d ${EXEDIR} ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    ERROR: Directory of executables does not exist. 
    Check the input: ${EXEDIR}

EOF
        exit
    fi
}

function set_mpi_ {

    cat << EOF
================================================================================
                                  MPI DIRECTORY                                                                                                                                          
================================================================================
    Please specify the directory of MPI executables or MPI modules.
    NOTE: Required version for ORCA 5.0.4 is OpenMPI 4.1.1.

    Default Option:

        /rds/general/user/jwb321/home/etc/modulefiles/openmpi-4.1.1_module

EOF

    
    read -p "   User Option: " MPIDIR
    MPIDIR=`echo ${MPIDIR}`

    if [[ -z ${MPIDIR} ]]; then

        MPIDIR='module load /rds/general/user/jwb321/home/etc/modulefiles/openmpi-4.1.1_module'

    fi

    if [[ ! -d ${EXEDIR} && (${EXEDIR} != *'module load'*) ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    ERROR: Directory or command does not exist. 
    Check the input: ${MPIDIR}

EOF
        exit
    fi

    if [[ ${MPIDIR} == *'module load'* ]]; then
        ${MPIDIR} > /dev/null 2>&1
        if [[ $? != 0 ]]; then
            cat << EOF
--------------------------------------------------------------------------------
    ERROR: Module specified not available. 
    Check the input: ${MPIDIR}

EOF
            exit
        fi
    fi
}

function copy_scripts_ {
    mkdir -p ${SCRIPTDIR}
    cp ${CTRLDIR}/settings_template ${SCRIPTDIR}/settings
    cp ${CTRLDIR}/orca_gen ${SCRIPTDIR}/orca_gen
    cp ${CTRLDIR}/orca_run ${SCRIPTDIR}/orca_run
    cp ${CTRLDIR}/orca_post ${SCRIPTDIR}/orca_post
    cp ${CTRLDIR}/orca_help ${SCRIPTDIR}/orca_help

    cat << EOF
    Modification sucessful at ${SCRIPTDIR}.
EOF
}



function set_settings_ {
    SETFILE=${SCRIPTDIR}/settings


    sed -i "/SUBMISSION_EXT/a\ .qsub" ${SETFILE}
    sed -i "/NCPU_PER_NODE/a\ 24" ${SETFILE}
    sed -i "/MEM_PER_NODE/a\ 100" ${SETFILE}
    sed -i "/NTHREAD_PER_PROC/a\ 1" ${SETFILE}
    sed -i "/JOB_TMPDIR/a\ ${EPHEMERAL}" ${SETFILE}
    sed -i "/MPIDIR/a\ ${MPIDIR}" ${SETFILE}
    sed -i "/EXECUTABLE/a\ ${EXEDIR}/orca" ${SETFILE}

    # Input file table

	LINE_PRE=`grep -nw 'PRE_CALC' ${SETFILE}`
    LINE_PRE=`echo "scale=0;${LINE_PRE%:*}+3" | bc`

    sed -i "${LINE_PRE}a\[jobname].gbw          *                      Orbital file" ${SETFILE}
    sed -i "${LINE_PRE}a\[jobname].out          *                      Orca output file" ${SETFILE}
    sed -i "${LINE_PRE}a\[jobname].inp          *                      Orca input file" ${SETFILE}
   
    # Reference file table

	LINE_REF=`grep -nw 'REF_FILE' ${SETFILE}`
    LINE_REF=`echo "scale=0;${LINE_REF%:*}+3" | bc`

    sed -i "${LINE_REF}a\[refname].bas          *                      Basis set file" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].xyz          *                      Coordinate file" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].gbw          *                      Orbital file" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].densities    *                      Electron density file" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].hess         *                      Hessian matrix file" ${SETFILE}
    sed -i "${LINE_REF}a\[refname].prop         *                      Properties file" ${SETFILE}
      
    # Post-processing file table

    LINE_POST=`grep -nw 'POST_CALC' ${SETFILE}`
    LINE_POST=`echo "scale=0;${LINE_POST%:*}+3" | bc`

    sed -i "${LINE_POST}a\[jobname].gbw          *                      Orbital file" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].densities    *                      Electron density file" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname]_property.txt *                      Property text file" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].hess         *                      Hessian matrix file" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].prop         *                      Properties file" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].trj          *                      Trajectory file" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].mdrestart    *                      MD restart file" ${SETFILE}
    sed -i "${LINE_POST}a\[jobname].ges          *                      Orbital guess file" ${SETFILE}

    # Job submission file template - should be placed at the end of file

    cat << EOF >> ${SETFILE}
-----------------------------------------------------------------------------------
#!/bin/bash  --login
#PBS -N \${V_JOBNAME}
#PBS -l select=\${V_ND}:ncpus=\${V_NCPU}:mem=\${V_MEM}:mpiprocs=\${V_PROC}:ompthreads=\${V_TRED}:avx2=true
#PBS -l walltime=\${V_WT}

echo "--------------------------------------------"
echo "               PBS Job Report"
echo "--------------------------------------------"
echo "  Start Date : \$(date)"
echo "  PBS Job ID : \${PBS_JOBID}"
echo "  Status"
qstat -f \${PBS_JOBID}
echo "--------------------------------------------"
echo ""

# number of cores per node used
export NCORES=\${V_NCPU}
# number of processes
export NPROCESSES=\${V_TPROC}

# Make sure any symbolic links are resolved to absolute path
export PBS_O_WORKDIR=\$(readlink -f \${PBS_O_WORKDIR})

# Set the number of threads
export OMP_NUM_THREADS=\${V_TRED}

# to sync nodes
cd \${PBS_O_WORKDIR}

# Load the MPI module
${MPIDIR}

# start calculation: command added below by orca_gen
-----------------------------------------------------------------------------------

EOF
    cat << EOF
    
--------------------------------------------------------------------------------
                                    SUCESSFUL                                                                                                                                          

    Parameters have been sucessfully set up in the settings file.
    File Location: ${SETFILE}

                                   EXITING NOW
--------------------------------------------------------------------------------
EOF
}
 

# Configure user alias

function set_commands_ {
    bgline=`grep -nw "# >>> begin ORCA job submitter settings >>>" ${HOME}/.bashrc`
    edline=`grep -nw "# <<< finish ORCA job submitter settings <<<" ${HOME}/.bashrc`

    if [[ ! -z ${bgline} && ! -z ${edline} ]]; then
        bgline=${bgline%%:*}
        edline=${edline%%:*}
        sed -i "${bgline},${edline}d" ${HOME}/.bashrc
    fi

    echo "# >>> begin ORCA job submitter settings >>>" >> ${HOME}/.bashrc
    echo "alias Porca='${SCRIPTDIR}/orca_gen -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias HELPorca='${SCRIPTDIR}/orca_help | tee -a ${SCRIPTDIR}/HELP'" >> ${HOME}/.bashrc
    echo "alias SETorca='cat ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "# <<< finish ORCA job submitter settings <<<" >> ${HOME}/.bashrc
 
}

function call_command_ {
    welcome_msg_
    get_scriptdir_
    copy_scripts_
    set_exe_
    set_mpi_
    set_settings_
    set_commands_
}

CONFIGDIR=`realpath $(dirname $0)`
CTRLDIR=`realpath ${CONFIGDIR}/`

call_command_
