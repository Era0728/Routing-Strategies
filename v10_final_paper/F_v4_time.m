function [ f ] =F_v4_time( source_cap, i, P_before, source )
%14节点，输入参数时刻，单独时刻优化
f = 0;
M = inf;
connect(1,:)=[zeros(1,1),1,M,M,1,M,M,M,M,M,M,M,M,M];
connect(2,:)=[zeros(1,2),1,1,1,M,M,M,M,M,M,M,M,M];
connect(3,:)=[zeros(1,3),1,M,M,M,M,M,M,M,M,M,M];
connect(4,:)=[zeros(1,4),1,M,1,M,1,M,M,M,M,M];
connect(5,:)=[zeros(1,5),1,M,M,M,M,M,M,M,M];
connect(6,:)=[zeros(1,6),M,M,M,M,1,1,1,M];
connect(7,:)=[zeros(1,7),1,1,M,M,M,M,M];
connect(8,:)=[zeros(1,8),M,M,M,M,M,M];
connect(9,:)=[zeros(1,9),1,M,M,M,1];
connect(10,:)=[zeros(1,10),1,M,M,M];
connect(11,:)=[zeros(1,11),M,M,M];
connect(12,:)=[zeros(1,12),1,M];
connect(13,:)=[zeros(1,13),1];
connect(14,:)=[zeros(1,14)];
Connect=connect+connect';

N = 0;
r(1,:)=[zeros(1,1),0.01938,N,N,0.05403,N,N,N,N,N,N,N,N,N];
r(2,:)=[zeros(1,2),0.04699,0.05811,0.05695,N,N,N,N,N,N,N,N,N];
r(3,:)=[zeros(1,3),0.06701,N,N,N,N,N,N,N,N,N,N];
r(4,:)=[zeros(1,4),0.01335,N,10e-6,N,10e-6,N,N,N,N,N];
r(5,:)=[zeros(1,5),10e-6,N,N,N,N,N,N,N,N];
r(6,:)=[zeros(1,6),N,N,N,N,0.09498,0.12291,0.06615,N];
r(7,:)=[zeros(1,7),10e-6,10e-6,N,N,N,N,N];
r(8,:)=[zeros(1,8),N,N,N,N,N,N];
r(9,:)=[zeros(1,9),0.03181,N,N,N,0.12711];
r(10,:)=[zeros(1,10),0.08205,N,N,N];
r(11,:)=[zeros(1,11),N,N,N];
r(12,:)=[zeros(1,12),0.22092,N];
r(13,:)=[zeros(1,13),0.17093];
r(14,:)=[zeros(1,14)];
R=r+r';

Q = 0.7;
W = 0;
cap_line(1,:)=[zeros(1,1),Q,W,W,Q,W,W,W,W,W,W,W,W,W];
cap_line(2,:)=[zeros(1,2),Q,Q,Q,W,W,W,W,W,W,W,W,W];
cap_line(3,:)=[zeros(1,3),Q,W,W,W,W,W,W,W,W,W,W];
cap_line(4,:)=[zeros(1,4),Q,W,Q,W,Q,W,W,W,W,W];
cap_line(5,:)=[zeros(1,5),Q,W,W,W,W,W,W,W,W];
cap_line(6,:)=[zeros(1,6),W,W,W,W,Q,Q,Q,W];
cap_line(7,:)=[zeros(1,7),Q,Q,W,W,W,W,W];
cap_line(8,:)=[zeros(1,8),W,W,W,W,W,W];
cap_line(9,:)=[zeros(1,9),Q,W,W,W,Q];
cap_line(10,:)=[zeros(1,10),Q,W,W,W];
cap_line(11,:)=[zeros(1,11),W,W,W];
cap_line(12,:)=[zeros(1,12),Q,W];
cap_line(13,:)=[zeros(1,13),Q];
cap_line(14,:)=[zeros(1,14)];
Capacity_line=cap_line+cap_line'; %kA
I_real = zeros(size(Connect));
U_real = zeros(size(Connect));

% load_expect_all = [
% %                0 0 0 0 0 0 0 0 0 0 0 0
% %                0 0 0 0 0 0 0 0 0 0 0 0
%                1 1 1 3 4 5 4 4 6 5 3 1
%                2 3 3 5 6 6 6 5 7 7 3 2
%                0 0 0 0 0 0 0 0 0 0 0 0
%                0 0 0 0 0 0 0 0 0 0 0 0
%                2 2 2 3 3 4 5 6 5 4 3 2
%                3 3 4 4 3 4 5 6 5 5 4 3
%                2 2 3 4 4 5 5 6 5 4 3 2
%                1 1 1 2 2 3 3 3 4 3 3 2
%                1 1 2 2 3 3 4 4 5 5 3 1];
load_expect_all = [0 0 0 0 0 0 0 0 0 0 0 0
                   0 0 0 0 0 0 0 0 0 0 0 0
                   0 0 0 0 0 0 0 0 0 0 0 0
                   1 2 3 4 4 3 2 1 2 2 2 3
                   4 5 6 6 7 7 8 8 7 5 4 3
                   0 0 0 0 0 0 0 0 0 0 0 0
                   2 2 3 3 4 4 3 3 2 2 1 1
                   0 0 0 0 0 0 0 0 0 0 0 0
                   1 1 1 2 2 2 2 2 1 1 1 1
                   2 2 2 3 3 3 4 4 3 2 2 1
                   2 2 3 3 4 4 5 5 4 4 3 2
                   2 2 3 3 2 2 1 1 2 1 2 1
                   2 3 3 4 4 4 3 3 4 2 2 1
                   2 2 4 5 4 3 4 4 3 4 2 1];
U_rated = 20;
eff = 0.97;

load_expect = load_expect_all(:,i);
source_expect = zeros(size(load_expect));

%加入可再生后要改
if length(source) == length(source_cap)
    for k = 1:1:length(source)
        source_expect(source(k)) = source_cap(k);
    end
else
    error = 1
end

data_I_expect = I_real;
data_U_expect = U_real;
[point, time] = size(load_expect);
% 
P_load = zeros(1,length(Connect));
P_out = zeros(1,length(Connect));
[content,index] = sort(load_expect,'descend');
for j = 1:1:point
    destination = index(j);
    P_demand = content(j);
    if P_demand > 0
    [ data, data_I_expect, data_U_expect, P_load, P_out] = Limited_ShortestPath_loss(Connect, data_I_expect, ...
        data_U_expect, P_load, P_demand, destination, U_rated, source, source_expect, Capacity_line, R, P_out, eff );
    end
end

a = [665,670,660,0,480,370,0,0];
b = [27.27,27.79,25.92,0,27.74,22.26,0,0];
c = [0.00222,0.00173,0.00413,0,0.00079,0.00712,0,0];
startup = [60000 60000 60000 60000 60000 60000 60000 60000];
if sum(P_load) >= sum(load_expect)
    for t = 1:1:length(source)
       f= f+a(t)+b(t)*P_out(source(t))+c(t)*P_out(source(t))^2;
    end
else
    f = 10^9;
end

for t = 1:1:length(source)
    if (P_before(t) == 0) && (P_out(source(t))>0)
        f = f+ startup(t);
    end
end


end

