function [xkp1] = f_dynamics(xk,uk,vk,delt,RBIHatk,P)
% f_dynamics : Discrete-time dynamics model for quadcopter.
%
% INPUTS
%
% xk --------- 15x1 state vector at time tk, defined as 
% 
%              xk = [rI', vI', e', ba', bg']'
%
%              where all corresponding quantities are identical to those
%              defined for E.statek in stateEstimatorUKF.m and where e is the
%              3x1 error Euler angle vector defined such that for an estimate
%              RBIHat of the attitude, the true attitude is RBI = D(e)*RBIHat,
%              where D(e) is the DCM formed from the error Euler angle vector
%              e.
%
% uk --------- 6x1 IMU measurement input vector at time tk, defined as
%
%              uk = [omegaBtilde', fBtilde']'
%
%              where all corresponding quantities are identical to those
%              defined for M in stateEstimatorUKF.m.
%
% vk --------- 12x1 process noise vector at time tk, defined as
%
%              vk = [vg', vg2', va', va2']'
%
%              where vg, vg2, va, and va2 are all 3x1 mutually-independent
%              samples from discrete-time zero-mean Gaussian noise processes.
%              These represent, respectively, the gyro white noise (rad/s),
%              the gyro bias driving noise (rad/s), the accelerometer white
%              noise (m/s^2), and the accelerometer bias driving noise
%              (m/s^2).
%
% delt ------- Propagation interval, in seconds.
%
% RBIHatk ---- 3x3 attitude matrix estimate at time tk.
%
%
% P ---------- Structure with the following elements:
%
%    quadParams = Structure containing all relevant parameters for the
%                 quad, as defined in quadParamsScript.m 
%
%     constants = Structure containing constants used in simulation and
%                 control, as defined in constantsScript.m 
%
%  sensorParams = Structure containing sensor parameters, as defined in
%                 sensorParamsScript.m
%
%
% OUTPUTS
%
% xkp1 ------- 15x1 state vector propagated to time tkp1
%
%+------------------------------------------------------------------------------+
% References:
%
%
% Author: Todd Humphreys
%+==============================================================================+  

if(abs(delt - P.sensorParams.IMUdelt) > 1e-9)
  error('Propagation time must be same as IMU measurement time');
end

rIk = xk(1:3);
vIk = xk(4:6);
ek = xk(7:9);
bak = xk(10:12);
bgk = xk(13:15);
omegaBtildek = uk(1:3);
fBtildek = uk(4:6);
vgk = vk(1:3);
vg2k = vk(4:6);
vak = vk(7:9);
va2k = vk(10:12);
RBIk = euler2dcm(ek)*RBIHatk;
e3 = [0;0;1];

rIkp1 = rIk + delt*vIk;
omegaBk = omegaBtildek - bgk - vgk; 
% The equation below assumes that the body reference frame has been defined
% such that the lever arm lB = 0
aIk = RBIk'*(fBtildek - bak - vak) - P.constants.g*e3;
edotk = eulerS(ek)*omegaBk;
vIkp1 = vIk + delt*aIk;
ekp1 = ek + delt*edotk;
bakp1 = P.sensorParams.alphaa*bak + va2k;
bgkp1 = P.sensorParams.alphag*bgk + vg2k;

xkp1 = [rIkp1;vIkp1;ekp1;bakp1;bgkp1];

% This is the S function from the section titled "Kinematic Equation for
% Euler Angles" from the course book. 
function [S] = eulerS(e)
cp = cos(e(1)); ct = cos(e(2));
sp = sin(e(1)); st = sin(e(2));
% If the Euler representation is singular, return a zero matrix.
if(abs(cp) < 1e-10)
  S = zeros(3,3);
else
  S = [ct, 0, st;
       sp*st/cp, 1, -ct*sp/cp;
       -st/cp, 0, ct/cp];
end

end
end