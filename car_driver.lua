-- A pwm motor driver written for my RedRacingRoadster
-- Author: Rony L. Batista <rony.batista29@gmail.com>
-- at: github.com/ronyb29/RedRacingRoadster


local PWM_FRECUENCY = 60

local x_forward_pin = 2
local x_backward_pin = 3
local z_forward_pin = 5
local z_backward_pin = 6

gpio.mode(x_forward_pin, gpio.OUTPUT, gpio.FLOAT)
gpio.mode(x_backward_pin, gpio.OUTPUT, gpio.FLOAT)
gpio.mode(z_forward_pin, gpio.OUTPUT, gpio.FLOAT)
gpio.mode(z_backward_pin, gpio.OUTPUT, gpio.FLOAT)

pwm.setup(x_forward_pin, PWM_FRECUENCY, 0)
pwm.setup(x_backward_pin, PWM_FRECUENCY, 0)
pwm.setup(z_forward_pin, PWM_FRECUENCY, 0)
pwm.setup(z_backward_pin, PWM_FRECUENCY, 0)

local function move_car(x, z)
    --todo use bit and to clamp values to 1 byte
    if x >= 1 then
        pwm.stop(x_forward_pin)
        pwm.setduty(x_backward_pin, x * 4)
        pwm.start(x_backward_pin)
    elseif x <= -1 then
        pwm.stop(x_backward_pin)
        pwm.setduty(x_forward_pin, x * -4)
        pwm.start(x_forward_pin)
    else
        pwm.stop(x_forward_pin)
        pwm.stop(x_backward_pin)
    end

    if z >= 1 then
        pwm.stop(z_forward_pin)
        pwm.setduty(z_backward_pin, z * 4)
        pwm.start(z_backward_pin)
    elseif z <= -1 then
        pwm.stop(z_backward_pin)
        pwm.setduty(z_forward_pin, z * -4)
        pwm.start(z_forward_pin)
    else
        pwm.stop(z_backward_pin)
        pwm.stop(z_forward_pin)
    end
end

move_car(0, 0)


return { move_car = move_car }
