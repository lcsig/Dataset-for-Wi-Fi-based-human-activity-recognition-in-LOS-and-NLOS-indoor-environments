%
% (c) 2008-2011 Daniel Halperin <dhalperi@cs.washington.edu>
%
function ret = qam16_ber(paramx)
    ret = 3/4*qfunc( sqrt( paramx / 5) );
end
