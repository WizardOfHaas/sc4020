program sc_test
    use plot
    implicit none

    real, allocatable :: x(:), y(:), l_x(:), l_y(:)
    real :: start_x, start_y, next_x, next_y, grain_r, tx, ty
    integer :: i, j, n_grains, hit_id

    real, external :: rand_loc

    n_grains = 500
    allocate(x(n_grains), y(n_grains), l_x(1000), l_y(1000))
    grain_r = 10.
    hit_id = 0

    CALL XSCALV (-1000.0, 1000.0, 0, 0)
    CALL YSCALV (-1000.0, 1000.0, 0, 0)

    !Generate cloud of dust
    do i = 1, n_grains
        x(i) = rand_loc(900.)
        y(i) = rand_loc(900.)
        !call circle(x(i), y(i), grain_r)
    end do

    call draw_grains(n_grains, x, y, grain_r)
    call framev(2)

    !Start tracing some rays
    start_x = 0.
    start_y = 0.

    !Choose random location to start with
    next_x = start_x - abs(rand_loc(2 * grain_r))
    next_y = start_y + rand_loc(2 * grain_r)

    i = 2
    l_x(1) = start_x
    l_y(1) = start_y
    
    l_x(2) = start_x
    l_y(2) = start_y

    do while(start_x < 1000. .and. start_x > -1000. .and. start_y < 1000. .and. start_y > -1000. .and. i < 1000)
        !Draw initial line
        !call linev(nxv(start_x), nyv(start_y), nxv(next_x), nyv(next_y))

        !Check if this hits a grain
        hit_id = 0

        do j = 1, n_grains
            if( &
                next_x < x(j) + grain_r .and. next_x > x(j) - grain_r .and. &
                next_y < y(j) + grain_r .and. next_y > y(j) - grain_r &
            ) then
                hit_id = j
            end if
        end do

        if(hit_id .ne. 0) then
            start_x = next_x
            start_y = next_y

            next_x = start_x + rand_loc(4 * grain_r)
            next_y = start_y + rand_loc(4 * grain_r)

            call draw_grains(n_grains, x, y, grain_r)
            call draw_path(i, l_x, l_y)
            call framev(2)
        else
            !Next line starts at current end point
            tx = next_x
            ty = next_y

            !Extend the line by a grain radius. This part is broken!
            next_x = next_x + sign(grain_r, next_x - start_x)
            next_y = next_y + sign(grain_r, next_y - start_y)

            start_x = tx
            start_y = ty
        end if

        i = i + 1

        l_x(i) = next_x
        l_y(i) = next_y
    end do

    call draw_grains(n_grains, x, y, grain_r)
    call draw_path(i, l_x, l_y)
    call framev(2)
end program sc_test

real function rand_loc(max) result(r)
    real :: max
    r = 2 * max * rand() - max
end function

subroutine draw_path(n, x, y)
    use plot

    integer :: n
    real :: x(n), y(n), r

    integer :: i

    do i = 1, n - 1
        call linev(nxv(x(i)), nyv(y(i)), nxv(x(i + 1)), nyv(y(i + 1)))
    end do
end subroutine

subroutine draw_grains(n, x, y, r)
    use plot

    integer :: n
    real :: x(n), y(n), r

    integer :: i

    do i = 1, n
        call circle(x(i), y(i), r)
    end do
end subroutine