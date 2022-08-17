module plot
    implicit none

    real :: scal_xl, scal_xr, fml, fmr, scal_yb, scal_yt, fmb, fmt, a, b, c, d

contains
    subroutine dec_to_bin(d, b, i)
        integer, intent(in) :: d
        integer(kind = 1), intent(out) :: b(36)
        integer, intent(out) :: i   

        integer :: val  

        val = d
        b = (/0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0/)  

        do i = 0, 35
            if(mod(val, 2) == 0) then
                b(36 - i) = 0
            else
               b(36 - i) = 1
            end if  

            val = val / 2   

            if(val == 0) then
                return
            end if
        end do
    end subroutine  

    subroutine bin_to_oct(b, o)
        integer(kind=1), intent(in) :: b(3)
        integer(kind=8), intent(out) :: o
        integer :: i    

        o = 0   

        do i = 0, 2
            o = o + b(3 - i) * 2 ** i
        end do
    end subroutine  

    subroutine print_ins(ins)
        integer(kind=1) :: ins(36)  

        write (*,*) ins
    end subroutine  

    subroutine output_bin(ins)
        integer(kind=1) :: ins(36)
        integer :: i, n
        integer(kind=8) :: o(12)

        n = 1   

        do i = 1, 12
            call bin_to_oct(ins(n:n + 3), o(i))
            n = n + 3
        end do

        print "(12(I0))", o
    end subroutine  

    subroutine output_oct(o)
        integer(kind=8) :: o(12)
        print "(12(I0))", o
    end subroutine  

    subroutine vector()
    end subroutine  

    !3 - Film advanced, no print out. 
    !2 - Film advanced, corners drawn, no ID. 
    !1 - Film advanced, ID printed, no corners.
    !0 - Film advanced, corners drawn, ID printed. 
    subroutine framev(n)
        integer :: n
        integer(kind = 8) :: adv(12)

        if(n == 2) then !Draw corners
            call line2v(0, 0, -20, 0)
            call line2v(0, 0, 0, 20)

            call line2v(0, 1000, -20, 0)
            call line2v(0, 1000, 0, -20)

            call line2v(1000, 0, 20, 0)
            call line2v(1000, 0, 0, 20)

            call line2v(1000, 1000, 20, 0)
            call line2v(1000, 1000, 0, -20)
        end if

        adv = (/4, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0/)
        call output_oct(adv)
    end subroutine  

    subroutine linev(ix1, iy1, ix2, iy2)
        integer :: ix1, iy1, ix2, iy2
        integer :: idx, idy

        !Calculate idx, idy
        idx = ix2 - ix1
        idy = iy1 - iy2

        call line2v(ix1, iy1, idx, idy)
    end subroutine

    subroutine line2v(ix1, iy1, idx, idy)
        integer :: ix1, iy1, idx, idy
        integer(kind = 1) :: ins(36), tmp(36)
        integer :: i

        !Define a VECTOR instruction
        ins = (/1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0/)    

        call dec_to_bin(abs(idx), tmp, i)   !Turn dx value into bin array, i holds length(if needed)
        ins(3:8) = tmp(31:36)               !Splice in dx value
    
        call dec_to_bin(ix1, tmp, i)
        ins(9:18) = tmp(27:36)  

        call dec_to_bin(abs(idy), tmp, i)
        ins(21:26) = tmp(31:36) 

        call dec_to_bin(iy1, tmp, i)
        ins(27:36) = tmp(27:36) 

        !Deal with signs on idx and idy
        if(idx > 0) then
            ins(19) = 1
        end if

        if(idy > 0) then
            ins(20) = 1
        end if

        call output_bin(ins)
    end subroutine  

    subroutine pointv(x, y, ns)
        real :: x, y
        integer :: ns

        call plotv(nxv(x), nyv(y), ns)
    end subroutine

    subroutine plotv(ix, iy, ns)
        integer :: ix, iy, ns, i

        integer(kind = 1) :: ins(36), tmp(36)

        !Define a PLOT instruction
        ins = (/0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0/)

        call dec_to_bin(ix, tmp, i)
        ins(9:18) = tmp(27:36)

        call dec_to_bin(abs(ns), tmp, i)
        ins(19:24) = tmp(31:36)

        call dec_to_bin(iy, tmp, i)
        ins(27:36) = tmp(27:36)

        call output_bin(ins)
    end subroutine

    subroutine aplotv(n, xarray, yarray, jx, jy, nc, markpt, ierr)
        integer :: n, jx, jy, hy, nc, ierr
        real :: xarray(n), yarray(n)
        integer :: markpt(nc)

        integer :: i

        do i = 1, n
            call pointv(xarray(i), yarray(i), markpt(1))
        end do

    end subroutine
    
    !These equations are all directly taken from the SC4020 programmer docs
    subroutine xscalv(xl, xr, ml, mr)
        real :: xl, xr
        integer :: ml, mr

        scal_xl = xl
        scal_xr = xr
        fml = real(ml)
        fmr = real(mr)

        a = ((1023. - fmr) - fml) / (xr - xl)
        b = fml - a * xl
    end subroutine

    subroutine yscalv(yb, yt, mb, mt)
        real :: yb, yt
        integer mb, mt

        scal_yb = yb
        scal_yt = yt
        fmb = real(mb)
        fmt = real(mt)

        c = -((1023. - fmt) - fmb) / (yt - yb)
        d = fmb - a * yb
    end subroutine

    integer function nxv(x) result(ix)
        real :: x

        ix = ixv(x)

        !Handle boundry checking
        if(x < scal_xl .or. x > scal_xr) then
            ix = 0
        end if
    end function

    integer function nyv(y) result (iy)
        real :: y

        iy = iyv(y)

        !Handle boundry checking
        if(y > scal_yt .or. y < scal_yb) then
            iy = 0
        end if
    end function

    integer function ixv(x) result(ix)
        real :: x

        ix = a * x + b
    end function

    integer function iyv(y) result (iy)
        real :: y

        iy = c * y + d
    end function

    !Now, my own stuff...
    subroutine circle(x, y, r)
        real :: x, y, r

        real :: last_x, last_y, next_x, next_y, theta
        integer :: i

        last_x = r * cos(theta) + x
        last_y = r * sin(theta) + y
        next_x = last_x
        next_y = last_y
        theta = 0.

        do i = 0, 100
            next_x = r * cos(theta) + x
            next_y = r * sin(theta) + y

            call linev(nxv(last_x), nyv(last_y), nxv(next_x), nyv(next_y))

            theta = theta + 0.1
            last_x = next_x
            last_y = next_y
        end do
    end subroutine
end module plot
