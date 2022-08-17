program sc_test
    use plot
    implicit none

    real :: x(2), y(2), vx(2), vy(2), m(2), dt, G, r(2)
    real :: last_x, last_y, tmp_v, el
    integer :: i

    real, external :: calc_v, rand_e

    CALL XSCALV (-1000.0, 1000.0, 0, 0)
    CALL YSCALV (-1000.0, 1000.0, 0, 0)

    x = (/0, 500/)
    y = (/0, 500/)
    vx = (/0, 0/)
    vy = (/0, 0/)
    m = (/1, 10/)
    r = (/50, 100/)

    el = -0.92
    dt = 36000
    G = 6.67E-11

    call circle(x(1), y(1), r(1))
    call circle(x(2), y(2), r(2))
    call framev(2)

    do i = 0, 500
        vx(1) = calc_v(x(1), x(2), m(2), vx(1), dt)
        vy(1) = calc_v(y(1), y(2), m(2), vy(1), dt)
        vx(2) = calc_v(x(2), x(1), m(1), vx(2), dt)
        vy(2) = calc_v(y(2), y(1), m(1), vy(2), dt)

        !Handle collision
        if(abs(x(1) - x(2)) <= sqrt(r(1)**2 + r(2)**2) .and. abs(y(1) - y(2)) <= sqrt(r(1)**2 + r(2)**2)) then
            vx(1) = el * rand_e() * vx(1)
            vy(1) = el * rand_e() * vy(1)

            vx(2) = el * rand_e() * vx(2)
            vy(2) = el * rand_e() * vy(2)
        end if

        x(1) = x(1) + vx(1) * dt
        y(1) = y(1) + vy(1) * dt
        x(2) = x(2) + vx(2) * dt
        y(2) = y(2) + vy(2) * dt

        call circle(x(1), y(1), r(1))
        call circle(x(2), y(2), r(2))
        call framev(2)
    end do
end program sc_test

real function calc_v(r1, r2, m, v, dt) result(tmp_v)
    real :: r1, r2, m, v, dt

    tmp_v = 0

    if(r1 .ne. r2) then
        tmp_v = v - sign(1., r1 - r2) * (6.67E-11 * m / (r1- r2)**2) * dt ** 2
    end if
end function

real function rand_e() result(r)
    !r = 0.5 * rand() + 0.5
    r = 1
end function