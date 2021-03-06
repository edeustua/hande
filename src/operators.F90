module operators

! Module for operators other than the Hamiltonian operator.

implicit none

contains

!=== Hubbard model (k-space) ===

!--- Kinetic energy ---

! Kinetic operator is diagonal in the Hubbard model in the Bloch basis.

    pure function kinetic0_hub_k(sys, f) result(kin)

        ! In:
        !    sys: system being studied.
        !    f: bit string representation of the Slater determinant.
        ! Returns:
        !    < D_i | T | D_i >, the diagonal Kinetic matrix elements, for
        !        the Hubbard model in momentum space.

        use determinants, only: decode_det
        use system, only: sys_t

        use const, only: p, i0

        real(p) :: kin
        type(sys_t), intent(in) :: sys
        integer(i0), intent(in) :: f(sys%basis%tot_string_len)

        integer :: i, occ(sys%nel)

        ! <D|T|D> = \sum_k \epsilon_k
        kin = 0.0_p
        call decode_det(sys%basis, f, occ)
        do i = 1, sys%nel
            kin = kin + sys%basis%basis_fns(occ(i))%sp_eigv
        end do

    end function kinetic0_hub_k

!--- Double occupancy ---

! \hat{D} = 1/L \sum_i n_{i,\uparrow} n_{i,downarrow} (in local orbitals) gives the
! fraction of sites which contain two electrons, where L is the total number of
! sites.  See Becca et al (PRB 61 (2000) R16287).

! In momentum space this becomes (similar to the potential in the Hamiltonian
! operator): 1/L^2 \sum_{k_1,k_2,k_3} c^{\dagger}_{k_1,\uparrow} c^{\dagger}_{k_2,\downarrow} c_{k_3,\downarrow} c_{k_1+k_2-k_3,\uparrow}
! Hence this is trivial to evaluate...it's just like (parts of) the Hamiltonian operator!

    pure function double_occ_hub_k(sys, f1, f2) result(occ)

        ! In:
        !    sys: system being studied.
        !    f1, f2: bit string representation of the Slater
        !        determinants D1 and D2 respectively.
        ! Returns:
        !    < D1 | \hat{D} | D2 >, the matrix element of the double occupancy
        !    operator, where the determinants are formed from momentum space
        !    basis functions.

        use excitations, only: excit_t, get_excitation
        use system, only: sys_t

        use const, only: p, i0

        real(p) :: occ
        type(sys_t), intent(in) :: sys
        integer(i0), intent(in) :: f1(sys%basis%tot_string_len), f2(sys%basis%tot_string_len)
        type(excit_t) :: excitation

        excitation = get_excitation(sys%nel, sys%basis, f1,f2)

        select case(excitation%nexcit)
        case(0)
            occ = double_occ0_hub_k(sys, f1)
        case(2)
            occ = double_occ2_hub_k(sys, excitation%from_orb(1), excitation%from_orb(2), &
                                    excitation%to_orb(1), excitation%to_orb(2),     &
                                    excitation%perm)
        case default
            occ = 0.0_p
        end select

    end function double_occ_hub_k

    pure function double_occ0_hub_k(sys, f) result(occ)

        ! In:
        !    sys: system being studied.
        !    f: bit string representation of the Slater determinant (unused,
        !       just for interface compatibility).
        ! Returns:
        !    < D_i | \hat{D} | D_i >, the diagonal matrix element for the double
        !    occupancy operator in the momentum space formulation of the Hubbard
        !    model.

        use system, only: sys_t

        use const, only: p, i0

        real(p) :: occ
        type(sys_t), intent(in) :: sys
        integer(i0), intent(in) :: f(sys%basis%tot_string_len)

        ! As with the potential operator, the double occupancy operator is
        ! constant for all diagonal elements (see slater_condon0_hub_k).

        occ = real(sys%nalpha*sys%nbeta,p)/(sys%lattice%nsites**2)

    end function double_occ0_hub_k

    pure function double_occ2_hub_k(sys, i, j, a, b, perm) result(occ)

        ! In:
        !    sys: system being studied.
        !    i,j:  index of the spin-orbital from which an electron is excited in
        !          the reference determinant.
        !    a,b:  index of the spin-orbital into which an electron is excited in
        !          the excited determinant.
        !    perm: true if D and D_i^a are connected by an odd number of
        !          permutations.
        ! Returns:
        !    < D | \hat{D} | D_ij^ab >, the matrix element of the
        !    double-occupancy operator between a determinant and a double
        !    excitation of it in the momemtum space formulation of the Hubbard
        !    model.

        use hubbard_k, only: get_two_e_int_hub_k
        use system, only: sys_t

        use const, only: p

        real(p) :: occ
        type(sys_t), intent(in) :: sys
        integer, intent(in) :: i, j, a, b
        logical, intent(in) :: perm

        ! This actual annihilation and creation operators of \hat{D} are
        ! identical to the off-diagonal operators of H.  Hence, we can use the
        ! same integrals and just scale accordingly...
        occ = get_two_e_int_hub_k(sys, i, j, a, b) / (sys%hubbard%u * sys%lattice%nsites)

        if (perm) occ = -occ

    end function double_occ2_hub_k

!=== Hubbard model (real space) ===

!--- Double occupancy ---

! \hat{D} = 1/L \sum_i n_{i,\uparrow} n_{i,downarrow} (in local orbitals) gives the
! fraction of sites which contain two electrons, where L is the total number of
! sites.  See Becca et al (PRB 61 (2000) R16287).

     pure function double_occ0_hub_real(sys, f) result(occ)

        ! In:
        !    sys: system being studied.
        !    f: bit string representation of the Slater determinant (unused,
        !       just for interface compatibility).
        ! Returns:
        !    < D_i | \hat{D} | D_i >, the diagonal matrix element for the double
        !    occupancy operator.

        use bit_utils, only: count_set_bits
        use real_lattice, only: get_coulomb_matel_real
        use system, only: sys_t

        use const, only: p, i0

        real(p) :: occ
        type(sys_t), intent(in) :: sys
        integer(i0), intent(in) :: f(sys%basis%tot_string_len)

        ! As for momentum space, can use standard integrals of the potential and
        ! then scale.

        occ = get_coulomb_matel_real(sys, f) / (sys%hubbard%u * sys%lattice%nsites)

     end function double_occ0_hub_real

!=== Molecular (integrals read in) ===

!--- One-body operator (arbitrary) ---

! Because we read in the integrals for generic systems, any one-body operator is
! identical in form.

    pure function one_body_mol(sys, f1, f2) result(occ)

        ! In:
        !    sys: system being studied.
        !    f1, f2: bit string representation of the Slater
        !        determinants D1 and D2 respectively.
        ! Returns:
        !    Hamiltonian matrix element between the two determinants,
        !    < D1 | O_1 | D2 >, where the determinants are formed from
        !    molecular orbitals read in from an FCIDUMP file and O_1 is
        !    a one-body operator.

        use excitations, only: excit_t, get_excitation
        use system, only: sys_t

        use const, only: p, i0

        real(p) :: occ
        type(sys_t), intent(in) :: sys
        integer(i0), intent(in) :: f1(sys%basis%tot_string_len), f2(sys%basis%tot_string_len)
        type(excit_t) :: excitation

        excitation = get_excitation(sys%nel, sys%basis, f1,f2)

        select case(excitation%nexcit)
        case(0)
            occ = one_body0_mol(sys, f1)
        case(1)
            occ = one_body1_mol(sys, excitation%from_orb(1), excitation%to_orb(1), excitation%perm)
        case default
            occ = 0.0_p
        end select

    end function one_body_mol

    pure function one_body0_mol(sys, f) result(intgrl)

        ! In:
        !    sys: system being studied.
        !    f: bit string representation of a Slater determinant, |D>.
        ! Returns:
        !    <D|O_1|D>, the diagonal Hamiltonian matrix element involving D for
        !    systems defined by integrals read in from an FCIDUMP file and O_1
        !    is a one-body operator.

        use determinants, only: decode_det
        use molecular_integrals, only: get_one_body_int_mol_nonzero
        use system, only: sys_t

        use const, only: p, i0

        real(p) :: intgrl
        type(sys_t), intent(in) :: sys
        integer(i0), intent(in) :: f(sys%basis%tot_string_len)

        integer :: occ_list(sys%nel)
        integer :: iel, iorb

        call decode_det(sys%basis, f, occ_list)

        ! <D | O_1 | D > = \sum_i <i|O_1|i>
        ! The integrals can only be non-zero if the operator is totally symmetric.

        intgrl = sys%read_in%dipole_core
        if (sys%read_in%one_body_op_integrals%op_sym == sys%read_in%pg_sym%gamma_sym) then
            do iel = 1, sys%nel
                iorb = occ_list(iel)
                intgrl = intgrl + get_one_body_int_mol_nonzero(sys%read_in%one_body_op_integrals, iorb, iorb, sys%basis%basis_fns)
            end do
        end if

    end function one_body0_mol

    pure function one_body1_mol(sys, i, a, perm) result(intgrl)

        ! In:
        !    sys: system being studied.
        !    i: the spin-orbital from which an electron is excited in
        !       the reference determinant.
        !    a: the spin-orbital into which an electron is excited in
        !       the excited determinant.
        !    perm: true if an odd number of permutations are required for
        !       D and D_i^a to be maximally coincident.
        ! Returns:
        !    < D | O_1 | D_i^a >, the matrix element of a one-body operator
        !        between a determinant and a single excitation of it for systems
        !        defined by integrals read in from an FCIDUMP file.

        use molecular_integrals, only: get_one_body_int_mol_real
        use system, only: sys_t

        use const, only: p

        real(p) :: intgrl
        type(sys_t), intent(in) :: sys
        integer, intent(in) :: i, a
        logical, intent(in) :: perm

        intgrl = get_one_body_int_mol_real(sys%read_in%one_body_op_integrals, i, a, sys)

        if (perm) intgrl = -intgrl

    end function one_body1_mol

    pure function one_body1_mol_excit(sys, i, a, perm) result(intgrl)

        ! In:
        !    sys: system being studied.
        !    i: the spin-orbital from which an electron is excited in
        !       the reference determinant.
        !    a: the spin-orbital into which an electron is excited in
        !       the excited determinant.
        !    perm: true if an odd number of permutations are required for
        !       D and D_i^a to be maximally coincident.
        ! Returns:
        !    < D | O_1 | D_i^a >, the matrix element of a one-body operator
        !        between a determinant and a single excitation of it for systems
        !        defined by integrals read in from an FCIDUMP file.

        ! WARNING: This function assumes that the D_i^a is a symmetry allowed
        ! excitation from D (and so the matrix element is *not* zero by
        ! symmetry).  This is less safe that one_body1_mol but much faster as it
        ! allows symmetry checking to be skipped in the integral lookups.

        use molecular_integrals, only: get_one_body_int_mol_nonzero
        use system, only: sys_t

        use const, only: p

        real(p) :: intgrl
        type(sys_t), intent(in) :: sys
        integer, intent(in) :: i, a
        logical, intent(in) :: perm

        intgrl = get_one_body_int_mol_nonzero(sys%read_in%one_body_op_integrals, i, a, sys%basis%basis_fns)

        if (perm) intgrl = -intgrl

    end function one_body1_mol_excit

!== Debug/test routines for operating on exact wavefunction ===

    subroutine analyse_wavefunction(sys, wfn, dets, proc_blacs_info)

        ! Analyse an exact wavefunction using the desired operator(s).

        ! In:
        !    sys: system being studied.
        !    wfn: exact wavefunction to be analysed.  wfn(i) = c_i, where
        !         |\Psi> = \sum_i c_i|D_i>.
        !    dets: list of determinants in the Hilbert space (bit string representation).
        !    proc_blacs_info: BLACS information describing distribution of wfn.

        use const, only: i0, p
        use parallel
        use system

        type(sys_t), intent(in) :: sys
        type(blacs_info), intent(in) :: proc_blacs_info
        real(p), intent(in) :: wfn(:)
        integer(i0), intent(in) :: dets(:,:)

        real(p) :: expectation_val(2), cicj
        integer :: idet, i, ii, ilocal, jdet, j, jj, jlocal, ndets

#ifdef PARALLEL
        integer :: ierr
        real(p) :: esum(2)
#endif
        integer :: iunit

        iunit = 6

        expectation_val = 0.0_p
        ndets = ubound(dets, dim=2)

        ! NOTE: we don't pretend to be efficient here but rather just get the
        ! job done...

        if (nprocs == 1) then
            do idet = 1, ndets
                select case(sys%system)
                case(hub_k)
                    expectation_val(1) = expectation_val(1) + wfn(idet)**2*kinetic0_hub_k(sys, dets(:,idet))
                    expectation_val(2) = expectation_val(2) + wfn(idet)**2*double_occ0_hub_k(sys, dets(:,idet))
                case(hub_real)
                    expectation_val(1) = expectation_val(1) + wfn(idet)**2*double_occ0_hub_real(sys, dets(:,idet))
                case(read_in)
                    expectation_val(1) = expectation_val(1) + wfn(idet)**2*one_body0_mol(sys, dets(:,idet))
                end select
                do jdet = idet+1, ndets
                    cicj = wfn(idet) * wfn(jdet)
                    select case(sys%system)
                    case(hub_k)
                        expectation_val(2) = expectation_val(2) + &
                                             2*cicj*double_occ_hub_k(sys, dets(:,jdet), dets(:,idet))
                    case (read_in)
                        expectation_val(1) = expectation_val(1) + &
                                             2*cicj*one_body_mol(sys, dets(:,jdet), dets(:,idet))
                    end select
                end do
            end do
        else
            do i = 1, proc_blacs_info%nrows, proc_blacs_info%block_size
                do ii = 1, min(proc_blacs_info%block_size, proc_blacs_info%nrows - i + 1)
                    ilocal = i - 1 + ii
                    idet =  (i-1)*proc_blacs_info%nproc_rows + proc_blacs_info%procx* proc_blacs_info%block_size + ii
                    select case(sys%system)
                    case(hub_k)
                        expectation_val(1) = expectation_val(1) + wfn(ilocal)**2*kinetic0_hub_k(sys, dets(:,idet))
                        expectation_val(2) = expectation_val(2) + wfn(idet)**2*double_occ0_hub_k(sys, dets(:,idet))
                    case(hub_real)
                        expectation_val(1) = expectation_val(1) + wfn(idet)**2*double_occ0_hub_real(sys, dets(:,idet))
                    case(read_in)
                        expectation_val(1) = expectation_val(1) + wfn(idet)**2*one_body0_mol(sys, dets(:,idet))
                    end select
                    do j = 1, proc_blacs_info%ncols, proc_blacs_info%block_size
                        do jj = 1, min(proc_blacs_info%block_size, proc_blacs_info%nrows - j + 1)
                            jlocal = j - 1 + jj
                            jdet = (j-1)*proc_blacs_info%nproc_cols + proc_blacs_info%procy*proc_blacs_info%block_size + jj
                            cicj = wfn(ilocal) * wfn(jlocal)
                            select case(sys%system)
                            case(hub_k)
                                expectation_val(2) = expectation_val(2) + &
                                                    cicj*double_occ_hub_k(sys, dets(:,idet), dets(:,jdet))
                            case (read_in)
                                expectation_val(1) = expectation_val(1) + &
                                                     2*cicj*one_body_mol(sys, dets(:,idet), dets(:,jdet))
                            end select
                        end do
                    end do
                end do
            end do
        end if

#ifdef PARALLEL
        call mpi_allreduce(expectation_val, esum, size(esum), mpi_preal, MPI_SUM, mpi_comm_world, ierr)
        expectation_val = esum
#endif

        if (parent) then
            select case(sys%system)
            case(hub_k)
                write (iunit,'(1X,a16,f12.8)') '<\Psi|T|\Psi> = ', expectation_val(1)
                write (iunit,'(1X,a16,f12.8)') '<\Psi|D|\Psi> = ', expectation_val(2)
            case(hub_real)
                write (iunit,'(1X,a16,f12.8)') '<\Psi|D|\Psi> = ', expectation_val(1)
                write (iunit,'()')
            case(read_in)
                write (iunit,'(1X,a18,f12.8)') '<\Psi|O_1|\Psi> = ', expectation_val(1)
                write (iunit,'()')
            end select
        end if

    end subroutine analyse_wavefunction

    subroutine print_wavefunction(filename, dets, proc_blacs_info, wfn)

        ! Print out an exact wavefunction.

        ! In:
        !    filename: file to be printed to.
        !    wfn: exact wavefunction to be printed out.  wfn(i) = c_i, where
        !    |\Psi> = \sum_i c_i|D_i>.
        !    dets: list of determinants in the Hilbert space (bit string representation).
        !    proc_blacs_info: BLACS information describing distribution of wfn.

        use const, only: i0, p

        use checking, only: check_allocate, check_deallocate
        use parallel

        character(*), intent(in) :: filename
        type(blacs_info), intent(in) :: proc_blacs_info
        real(p), intent(in) :: wfn(:)
        integer(i0), intent(in) :: dets(:,:)

        integer :: idet, i, ii, ilocal, iunit

#ifdef PARALLEL
        integer :: ierr
        integer :: proc_info(2, 0:nprocs-1), info(2), proc
        real(p), allocatable :: wfn_recv(:)
        integer :: stat(MPI_STATUS_SIZE)
        integer, parameter :: comm_tag = 123
#endif

        if (parent) then
            open(newunit=iunit,file=filename,status='unknown', position='append')
        end if

        if (nprocs == 1) then
            do idet = 1, size(wfn)
                write (iunit,*) idet, dets(:,idet), wfn(idet)
            end do
        else
#ifdef PARALLEL
            ! Set up for receiving parts of the wavefunction from other
            ! processors.
            info = (/proc_blacs_info%nrows, proc_blacs_info%procx/)
            call mpi_gather(info, 2, mpi_integer, proc_info, 2, &
                             mpi_integer, root, mpi_comm_world, ierr)

            if (parent) then
                allocate(wfn_recv(maxval(proc_info(1,:))), stat=ierr)
                call check_allocate('wfn_local', maxval(proc_info(1,:)), ierr)
                ! Write out from root.
                call write_wavefunction_parallel(proc_blacs_info%nrows, proc_blacs_info%procx, wfn)
                ! Write out from other processors.
                do proc = 1, nprocs-1
                    call mpi_recv(wfn_recv, proc_info(1,proc), mpi_preal, proc, comm_tag, mpi_comm_world, stat, ierr)
                    call write_wavefunction_parallel(proc_info(1,proc), proc_info(2,proc), wfn_recv)
                end do
                deallocate(wfn_recv, stat=ierr)
                call check_deallocate('wfn_local', ierr)
            else
                ! Send data from from other processors.
                call mpi_send(wfn, proc_blacs_info%nrows, mpi_preal, root, comm_tag, mpi_comm_world, ierr)
            end if
#endif
        end if

        if (parent) close(iunit,status='keep')

        contains

            subroutine write_wavefunction_parallel(nrows, procx, wfn_curr)

                integer, intent(in) :: nrows, procx
                real(p), intent(in) :: wfn_curr(nrows)

                do i = 1, nrows, proc_blacs_info%block_size
                    do ii = 1, min(proc_blacs_info%block_size, nrows - i + 1)
                        ilocal = i - 1 + ii
                        idet =  (i-1)*proc_blacs_info%nproc_rows + procx* proc_blacs_info%block_size + ii
                        write (iunit,*) idet, dets(:,idet), wfn_curr(ilocal)
                    end do
                end do

            end subroutine write_wavefunction_parallel

    end subroutine print_wavefunction

end module operators
