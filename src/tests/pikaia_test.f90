!*****************************************************************************************
!****u* PIKAIA/pikaia_test
!
!  NAME
!    pikaia_test
!    
!  DESCRIPTION
!    Sample driver program for pikaia.  
!    Based on the xpikaia routine.
!
!  AUTHOR
!    Jacob Williams : 3/9/2015
!
!  SOURCE

    program pikaia_test

    use pikaia_module, only: pikaia_class
    use,intrinsic :: iso_fortran_env, wp => real64

    implicit none
    
    integer,parameter :: n = 2  !dimension of problem (number of optimization variables)
    
    integer                 :: seed,status
    real(wp),dimension(n)   :: x
    real(wp)                :: f
    integer                 :: ierr,iunit,istat
    real(wp),dimension(n)   :: xl,xu
    type(pikaia_class)      :: p
    logical                 :: header_written
    real                    :: tstart,tend

    character(len=*),parameter :: filename = 'pikaia_test.txt'

    !the user enters a new seed value to use:
    write(output_unit,fmt='(A)') 'Enter random number seed: '
    read(input_unit,fmt='(I10)',iostat=ierr) seed
    if (ierr/=0) stop 'Invalid input.'

    !output file:
    open(newunit=iunit,file=filename,iostat=istat)
    if (istat/=0) stop 'error opening output file.'
    header_written = .false.

    !initial guess:
    write(output_unit,'(A)') ''
    write(output_unit,'(A)') ' TWOD Example'
    write(output_unit,'(A)') ''

    x = 0.0_wp
    xl = 0.0_wp
    xu = 1.0_wp
    
    !initialize the class:
    call p%init(n,xl,xu,twod,status,&
                iter_f              = report_iteration,&
                ngen                = 1000,&
                nd                  = 9,&
                ivrb                = 1,&    !0,1,2
                convergence_tol     = 1.0e-6_wp,&
                convergence_window  = 200,&
                iseed               = seed)

    !Now call pikaia:
    call cpu_time(tstart)
    call p%solve(x,f,status)
    call cpu_time(tend)

    !Print the results:
    write(output_unit,'(A)') ''
    write(output_unit,'(A,1X,*(I4))')    '  status: ',status
    write(output_unit,'(A,1X,*(F12.6))') '       x: ',x
    write(output_unit,'(A,1X,*(F12.6))') '       f: ',f
    write(output_unit,'(A)') ''
    write(output_unit,'(A,1X,F12.6,A)')  'run time: ',tend-tstart,' sec'
    write(output_unit,'(A)') ''

    !-------------------------

    !initial guess:
    write(output_unit,'(A)') ''
    write(output_unit,'(A)') ' ROSENBROCK Example'
    write(output_unit,'(A)') ''

    x  = 0.5_wp
    xl = 0.0_wp
    xu = 2.0_wp
    
    !initialize the class:
    call p%init(n,xl,xu,rosenbrock,status,&
                np                  = 500,&        !try a larger population for this one
                ngen                = 1000,&
                nd                  = 9,&
                convergence_tol     = 1.0e-10_wp,& !tighter tolerance also
                convergence_window  = 200,&
                iseed               = seed)

    !Now call pikaia:
    call cpu_time(tstart)
    call p%solve(x,f,status)
    call cpu_time(tend)

    !Print the results:
    write(output_unit,'(A)') ''
    write(output_unit,'(A,1X,*(I4))')    '  status: ',status
    write(output_unit,'(A,1X,*(F12.6))') '       x: ',x
    write(output_unit,'(A,1X,*(F12.6))') '       f: ',f
    write(output_unit,'(A)') ''
    write(output_unit,'(A,1X,F12.6,A)')  'run time: ',tend-tstart,' sec'
    write(output_unit,'(A)') ''

    close(iunit,iostat=istat)

    contains
      
        subroutine twod(me,x,f)

        ! Compute sample fitness function 
        ! (a smooth 2-d landscape)

        implicit none

        !Input/output:
        class(pikaia_class),intent(inout) :: me
        real(wp),dimension(:),intent(in)  :: x
        real(wp),intent(out)              :: f

        !Constant
        real(wp),parameter  :: pi=acos(-1.0_wp)
        real(wp),parameter  :: sigma2=0.15_wp
        integer,parameter   :: nn = 9

        !Local
        real(wp) :: rr

        if (x(1)>1.0_wp .or. x(2)>1.0_wp) then
            write(output_unit,*) 'Error in function twod: invalid inputs.'
            write(output_unit,*) 'x(1)=',x(1),'>1.0'
            write(output_unit,*) 'x(2)=',x(2),'>1.0'
            stop
        else
            rr=sqrt( (0.5_wp-x(1))**2+ (0.5_wp-x(2))**2)
            f=cos(rr*nn*pi)**2 *exp(-rr**2/sigma2)
        end if
        
        end subroutine twod   

        subroutine rosenbrock(me,x,f)

        ! Rosenbrock function for testing the algorithm.
        ! The minimum is at f(1,1) = 0.
        ! http://en.wikipedia.org/wiki/Rosenbrock_function

        implicit none

        class(pikaia_class),intent(inout)   :: me
        real(wp),dimension(:), intent(in)   :: x
        real(wp),intent(out)                :: f

        real(wp),parameter :: one     = 1.0_wp
        real(wp),parameter :: hundred = 100.0_wp
        
        !the rosenbrock function:
        f = (one-x(1))**2 + hundred*(x(2)-x(1)**2)**2

        f = -f    !since pikaia maximizes
        
        end subroutine rosenbrock

        subroutine report_iteration(me,iter,x,f)

        ! A simple iteration reporting function.
        ! Writes iter,x,f to the output file.

        implicit none

        class(pikaia_class),intent(inout)  :: me   
        integer,intent(in)                 :: iter 
        real(wp),dimension(:),intent(in)   :: x    
        real(wp),intent(in)                :: f

        character(len=10),dimension(n) :: xheader
        integer :: i

        !the first time it is called, also write a header:
        if (.not. header_written) then
            do i=1,n
                write(xheader(i),'(I10)') i
                xheader(i) = 'X'//trim(adjustl(xheader(i)))
                xheader(i) = repeat(' ',10-len_trim(xheader(i)))//xheader(i)
            end do
            write(iunit,'(A5,1X,*(A10,1X))') 'ITER',xheader,'F'
            header_written = .true.
        end if

        write(iunit,'(I5,1X,*(F10.6,1X))') iter,x,f

        end subroutine report_iteration

    end program pikaia_test
!*****************************************************************************************