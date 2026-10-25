# Bash and Make scripts

## Compiling (legacy) code

To compile, open a terminal in the uppermost directory, where the `src` and `pkgs`
folders are located, and run:

 `make -j`

To test the compilation, run:

 `make test`

All build, install, and test outputs stay inside the top directory: the
locations `MS_INST` (bin, lib, include), `msBilDir` (build), and `MS_TEST_DIR`
(test results) can be set in a `.env` file there (see `.env.example`), and
must be inside that directory; otherwise, `make` stops.

Once everything has compiled successfully, to clean the temporary files, run:

 `make clean`

The above command can be run inside most subfolders wherever a
`makefile` or `Makefile` is present. The libraries (those with a `makefile`)
will be compiled before the apps that contain `Makefile`s.

Compilation requires GNU (Linux) Make, CMake, a C++ compiler, and MPI. The compilation has been tested using g++ (version 5+, default)
and Intel 2018 compilers.

For modules that have `pkgs/foamxm` as a dependency: if you have
any other OpenFOAM installation on your machine, you need to temporarily ***deactivate
your OpenFOAM installation when compiling*** this code to avoid conflicts between
the `foamxm` provided here and your OpenFOAM installation.
Additionally, you need to install `foamxm` dependencies; on Ubuntu, this can be done
by running:
`sudo apt install mpi-default-dev flex libscotch-dev`

# Tests and demos
To test the code, run:

 `make test`

This should copy a series of input files/scripts into a `test_runs` folder and
run a series of relatively quick test cases (see `README.md` files in
subdirectories).
Running tests additionally requires Python packages `pnmkit` and `image3kit`.


# Technical Notes for Coding Agents

GNU Makefiles are used primarily for code compilation and
running quick tests by developers.
These are migrated to Pyhon only in pnmkit package, which consumes these porescale apps as optional dependencies.

Automated tests are written using input files for C++ codes, new C++
executables testing the internals of the code, and Python scripts. 
All of these can be run using the `make test` command, which uses the
`script/testApp` Bash script.

All scripts, either for testing or production, that require mathematical
calculations or plotting and are not performance-critical are developed in Python.

Bash shell scripts are used to run Makefiles and Python scripts,
either for testing or in production to simplify running OpenFOAM
solvers.


The `foam.bashrc` file contains Bash macros for managing OpenFOAM run cases,
which, together with `bashrc` (which contains installation variables), is
required for running the compiled applications.


---------

## Caution

The scripts here use recursive `make`. They modify and delete files on
your system: the top directory where files are modified, generated, or
deleted is called `msRoot`, which by default points two directories
above the location of these scripts themselves. Therefore, if you consider
using these scripts for building your applications, make sure they are
nested inside two subfolders dedicated to source code. Here is
what the directory structure should look like:


- `apps/ -------------------- msRoot directory`

    - `src/ ----------------- -- source code`
        * `script/ ---------- -- ** this module, build & install`
        * `include/ --------- -- ** C++ utility codes`
        * `...`

    - `pkgs/ ---------- -- external/third-party source code`
        * `foamxm ---------- -- ** a minified OpenFOAM `
        * `...`

    - `test_runs/ ----------- -- test folder (auto-created)`
    - `bin/ ----------------- -- executables folder (auto-created/deleted)`
    - `lib/ ----------------- -- library files (auto-created/deleted)`
    - `share/ --------------- -- configuration files (auto-created/deleted)`
    - `build/ --------------- -- temporary files (auto-created/deleted)`
    - `...`


As shown above, this `script` folder is typically located in `src`
(which holds actively changed source code in subdirectories).
The less frequently changed source code is placed in the
`pkgs` directory.
The `build`, `bin`, `lib`, `test_runs`, and `share` folders are auto-generated and should not be used to store
any user data --these are removed by the `make distclean` command.



## Makefile.in usage

 In `Makefile`s, define the variable `tsts` together with `USE_msTEST=1`
 and `srcs` with `USE_msMAKE=1`. If not defined, `srcs` will be set
 to all `.cpp` files. Example Makefiles can be found in `image3kit/vxlToFoam`
 (single `source.cpp` apps) or `pnextract` (multiple `source.cpp` files).

