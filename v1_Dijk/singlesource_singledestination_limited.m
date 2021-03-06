function [ data, Status_after, status_after ] = singlesource_singledestination_limited( Map, source, destination, Status_before, Capacity, demand)
    Map_temp = Map;
    demand_temp = demand;
    Status_temp = Status_before;
    flag = true;
    j=1;
    data={};
    % from Status to status
    status = triu(Status_temp);
    [row,col] = find(status<0);
    for num = 1:1:length(row)
        status(col(num),row(num)) = -status(row(num),col(num));
        status(row(num),col(num)) = 0;
    end
    
    while flag
        % modify map
        compare_positive = Capacity - Status_temp;
        [xp,yp] = find(compare_positive == 0);
        for k=1:1:length(xp)
            if xp(k)<yp(k)
                Map_temp(xp(k),yp(k)) = inf;
            end
        end
        compare_negative = Capacity + Status_temp;
        [xn,yn] = find(compare_negative == 0);
        for k=1:1:length(xn)
            if xn(k)<yn(k)
                Map_temp(yn(k),xn(k)) = inf;
            end
        end
        % find route
        [ distance_temp, route_temp ] = singlesource_singledestination( Map_temp, source, destination );
%         [ distance_temp, route_temp ] = Dijk( Map_temp, source, destination );
        status_temp = status;
        temp=[];
        for i=1:1:length(route_temp)-1
            status_temp(route_temp(i),route_temp(i+1)) = status(route_temp(i),route_temp(i+1))+demand_temp;
        end
        Status_temp = status_temp - status_temp';
        compare = Capacity - abs(Status_temp);    
        for i=1:1:length(route_temp)-1
            temp = [temp, compare(route_temp(i),route_temp(i+1))];
        end
        % judge capacity limitation
        a = min(min(temp));
        if a>=0
            data{j}.capacity_trans = demand_temp;
            data{j}.distance = distance_temp;
            data{j}.route = route_temp;
            for i=1:1:length(route_temp)-1
                status(route_temp(i),route_temp(i+1)) = status(route_temp(i),route_temp(i+1))+demand_temp;
            end
            Status_temp = status - status';
            flag = false;
        else
            [m,n] = find(compare == a);
            for k=1:1:length(m)
                if m(k)<n(k)
                    real = demand_temp + compare(m(k),n(k));
                    k=length(m)+1;
                end
            end
            data{j}.capacity_trans = real;
            data{j}.distance = distance_temp;
            data{j}.route = route_temp;
            j=j+1;
            demand_temp = demand_temp - real;
            for i=1:1:length(route_temp)-1
                status(route_temp(i),route_temp(i+1)) = status(route_temp(i),route_temp(i+1))+real;
            end
            Status_temp = status - status';
        end 
    end
    
    Status_after = Status_temp;
    status_after = triu(Status_after);
    [row,col] = find(status_after<0);
    for num = 1:1:length(row)
        status_after(col(num),row(num)) = -status_after(row(num),col(num));
        status_after(row(num),col(num)) = 0;
    end
    
end