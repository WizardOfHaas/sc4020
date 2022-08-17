program sc_test
    use plot
    implicit none

    integer :: x, y, dx, dy, i, inc, jnc
    real :: Z0, Z1, Z2

    !Lets try to do a plot...
    x = 0
    y = 300
    dx = 63
    dy = 63

    CALL XSCALV (-511.0, 512.0, 0, 0)
    CALL YSCALV (-511.0, 512.0, 0, 0)

    Z0 = 0.0
    Z1 = 4.0
    Z2 = 4.0
    CALL POINTV (Z0, Z0, -16)
    DO 5 I= 1, 63
    INC = I
    JNC= -INC
    CALL LINE2V (NXV (Z1), NYV (Z0), 0, INC)
    CALL LINE2V (NXV (Z2), NYV (Z0), 0, JNC)
    CALL LINE2V (NXV (Z0), NYV (Z1), JNC, 0)
    CALL LINE2V (NXV (Z0), NYV (Z2), INC, 0)
    Z1 = Z1 + 3.0
5   Z2 = Z2-3.0 

    call framev(2)
end program sc_test
