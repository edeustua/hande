.. _prereq:

Prerequisites
=============

HANDE builds upon several well-written, efficient libraries to aid portability,
efficiency and sustainability.

Dependencies
------------

Fortran and C compilers
    HANDE is written in (mostly) Fortran 2003 with some C code.  We have tested HANDE
    using GCC, Intel, Cray and IBM compilers and are interested in hearing of use with
    other compilers.

    .. note::

        HANDE is relatively aggressive in adopting new language features and hence
        requires a fairly modern Fortran compiler.  In particular, gfortran 5.5 or earlier
        is unlikely to successfully compile HANDE. We regularly test with gfortran 6 and
        gfortran 7.

LAPACK and BLAS
    Available from http://www.netlib.org/lapack/ and http://www.netlib.org/blas/ and
    vendor implementations.  Typically installed on HPC systems and available from package
    manager.  This is only required for the FCI functionality in HANDE; the performance of
    the QMC algorithms do not depend upon the quality of the LAPACK and BLAS libraries
    used.
lua 5.3
    Lua (available from http://www.lua.org) is required.  HANDE links to the lua library,
    which is used for parsing the input file.  No performance critical code is written in
    lua.

    .. note::

        A different version of the AOTUS library (which is included with HANDE) is
        needed to use lua 5.2 due to API changes.  This is also provided with HANDE
        (in the lib/aotus-5.2 directory).  To use it, set the variable lua_52 to any
        non-empty value in the config file.

MPI (parallel compilation only)
    MPI 2 is required.  We have used a variety of implementations (including OpenMPI and
    various vendor implementations).
scalapack (parallel compilation only)
    Available from http://www.netlib.org/scalapack/ and vendor implementations.  Often
    already installed on HPC systems, included in Intel Maths Kernel Library and can be
    installed from most package managers.
python 2.7+ or python 3.2+
    Almost all tools packaged with HANDE are written in python.

    .. note::

        python 2.6 or earlier python 3 versions **may** be sufficient but will probably
        require additional work.  In particular, the argparse module (included from 2.7
        and 3.2 onwards) is required and installing (especially recent versions of )
        pandas  may be problematic.  Using a recent version of python is highly
        recommended.
pandas 0.14.1+
    The HANDE data analysis tools build heavily upon the python scientific
    stack.  In particular, pandas (available from http://pandas.pydata.org) is required
    for the ``pyhande`` module and analysis scripts, almost all of which build upon
    ``pyhande``.  pandas is not required for running HANDE but is highly recommended for
    data analysis (though strictly speaking is only required if ``pyhande`` is used,
    either directly or via analysis scripts).

Bundled dependencies
--------------------

AOTUS
    AOTUS provides a nice Fortran wrapper to Lua's C-API.  For convenience (given that
    module files are Fortran-specific), AOTUS is included in the HANDE source
    distribution.

Optional dependencies
---------------------

The following are optional depedencies which add useful (in some cases almost critical)
functionality.  However, they are less likely to be compiled on HPC systems so for ease of
testing the functionality which depends upon them can be disabled at compile-time.

HDF5
    HDF5 is a library for storing scientific data and is used in HANDE for checkpointing
    (i.e. writing and reading restart files) in QMC calculations.

    Highly recommended.  Disabling HDF5 removes the ability to perform any checkpointing.

    .. note::

        HANDE requires the Fortran 2003 interface to HDF5, which is not compiled by
        default (see below), as this offers substantial advantages when working with
        dynamically sized arrays containing variables of arbitrary kinds/precision.

libuuid
    Provenance of a calculation, and the output file(s) produced by it, is an important
    topic, currently the subject of much debate in computational science.  HANDE generates
    a universally unique identifier (UUID), which is included in all files it produces.

    Highly recommended but can be disabled without impacting on performance (but perhaps
    not on the user's sanity).

    .. note::

        Some Linux distributions install libuuid but require an additional package (e.g.
        uuid-dev) to be installed in order for libuuid to exist on default search paths.
        Some luck may be found by looking under /lib or /lib64 instead of /usr/lib and
        /usr/lib64.
TRLan
    Required for (and only for) performing FCI calculations using the Lanczos algorithm.
    Available from http://crd-legacy.lbl.gov/~kewu/trlan.html.

Compilation and installation notes
----------------------------------

Some notes on compiling the less common dependencies.

.. note::

    The following are guidelines and the links provided are not necessarily the latest
    version of each package. Checking for the latest version is highly recommded.

lua
^^^

Lua is straightforward to compile.  For example:

.. code-block:: bash

    $ wget -O - http://www.lua.org/ftp/lua-5.3.4.tar.gz | tar xvzf -
    $ cd lua-5.3.4
    $ make linux
    $ make install INSTALL_TOP=$HOME/local

will install the lua program and library to subdirectories in $HOME/local.  It is usually
fine to compile lua using the GCC compiler and link HANDE against it using another
compiler family (e.g. Intel).

HDF5
^^^^

HDF5 uses the GNU autotools build system, so is also straightforward to compile.  For
example:

.. code-block:: bash

    $ wget -O - https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.19/src/hdf5-1.8.19.tar.gz | tar xvzf -
    $ cd hdf5-1.8.19
    $ ./configure --prefix=$HOME/local --enable-fortran --enable-fortran2003 --enable-cxx
    $ make
    $ make install

will compile HDF5 and install it to subdirectories in $HOME/local.  By default this will
use the GCC compiler suite; other compilers can be used by setting the CC, CXX and F77
environment variables.  Note the use of ``--enable-fortran2003``; the Fortran 2003
interface is required by HANDE.

pandas
^^^^^^

Pandas can be installed by

.. code-block:: bash

    $ pip install pandas

If you do not have root access, you can install the library locally with:

.. code-block:: bash

    $ pip install pandas --user

Alternatively, where pip is not available, one can install it locally:

.. code-block:: bash

    $ wget -O - https://github.com/pandas-dev/pandas/releases/download/v0.21.0/pandas-0.21.0.tar.gz | tar -xzvf -
    $ cd pandas-0.21.0
    $ python setup.py build
    $ python setup.py install

Again, pandas can be installed locally by replacing the final command with:

.. code-block:: bash

    $ python setup.py install --user
