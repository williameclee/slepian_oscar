%% KERNELCP_DEMO5
% This is demo 5 from KERNELCP.
%
% See also
%   KERNELCP, KERNELCP_DEMO1, KERNELCP_DEMO2, KERNELCP_DEMO3, KERNELCP_DEMO4
%
% Last modified by
%   2024/07/12, williameclee@arizona.edu (@williameclee)

function kernelcp_demo5
    Lmax = 22;
    dom = 'greenland';
    K2 = kernelc(Lmax, dom);
    K1 = kernelcp(Lmax, dom);
    difer(K2 - K1)
end
