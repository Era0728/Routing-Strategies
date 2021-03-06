function [ data, I_real, U_real, P_load, P_generate] = Limited_ShortestPath_loss_Priority(Connect, I_real, U_real, P_load, P_demand, ...
            destination, U_rated, source, Capacity_source, Capacity_line, R, P_generate, eff, priority)
    % ieee14节点，modified，有可再生能源，没有优先级，可再生能源电源自己节点上可以直接带负载
    P_load(destination) = P_load(destination) + P_demand; % record the demand
    P_demand_temp = P_demand;
    Map_temp = Connect;
    I_real_temp1 = I_real;
    I_real_temp2 = I_real;
    U_real_temp1 = U_real;
    U_real_temp2 = U_real;
    source_temp = source;

    bb = find(Capacity_source(source) == 0);  % source停机情况
    source_temp(bb) = -1;
    
    flag = true;
    j=1;
    data={};

    while flag
        I0_temp = P_demand_temp/U_rated;
        % modify map
        compare_line = Capacity_line - I_real_temp2;
        [x,y] = find(compare_line == 0);
        for k = 1:1:length(x)
           if x(k)~=y(k)
              Map_temp(x(k), y(k)) = inf;
           end
        end
        [ Map_temp ] = Map_cal( Map_temp, I_real_temp2, I0_temp, R, U_rated, eff );
        % modify source
        compare_source = Capacity_source - P_generate';
        aa = find(compare_source(source) <= Capacity_source(source)*0.001);
        source_temp(aa) = -1;
        % priority
        [available, location] = ismember(priority, source_temp);
        priority_index = find(available == 1);
        if ~isempty(priority_index)
            distance_temp_diffsource = [];
            for t=1:1:length(priority_index)
%                 if source_temp2(t) > 0
                    [ distance_temp1, route_temp ] = ShortestPath( Map_temp, priority(priority_index(t)), destination );
                    data_temp{t}= route_temp;
                    distance_temp_diffsource(t) = distance_temp1;
%                 else
%                     data_temp{t}= 'null';
%                     distance_temp_diffsource(t) = inf;
%                 end
            end
            if min(distance_temp_diffsource) == Inf %可再生电源中没有满足条件的最短路径,尝试其他类型电源
                location(find(location == 0)) = [];
                source_temp2 = source_temp;
                source_temp2(location) = [];
                
                distance_temp_diffsource = [];
                for t=1:1:length(source_temp2)
                    if source_temp2(t) > 0
                        [ distance_temp1, route_temp ] = ShortestPath( Map_temp, source_temp2(t), destination );
                        data_temp{t}= route_temp;
                        distance_temp_diffsource(t) = distance_temp1;
                    else
                        data_temp{t}= 'null';
                        distance_temp_diffsource(t) = inf;
                    end
                end
                if min(distance_temp_diffsource) == Inf %没有满足条件的最短路径
                    data{j}.capacity_trans = P_demand_temp;
                    data{j}.distance = inf;
                    data{j}.route = 'null';
                    [ p_in, p_out ] = Power_flow( destination, I_real_temp2, U_real_temp2, U_rated );
                    P_present = p_in *eff - p_out;
                    P_load(destination) = P_present;
                    break;
                else
                    tt = find(distance_temp_diffsource==min(distance_temp_diffsource));  %%%%%范围扩大一下
                    if length(tt)>1 % 超过一条最短路径，判断真实损耗
                        for k = 1:1:length(tt)
                            route_temp = data_temp{tt(k)};
                            [ I_real_temp3, U_real_temp3 ] = real_IU_calculate( route_temp, I_real_temp2, U_real_temp2, P_load, U_rated, R, P_generate, eff );
                            powerloss_temp(k) = sum(sum((I_real_temp3.^2.*R)));
                        end
                        index_temp = find(powerloss_temp==min(powerloss_temp));
                        if length(index_temp)>1
                            index = tt(index_temp(1));
                        else
                            index = tt(index_temp);
                        end
                        capacity_trans_temp = I0_temp;
                        distance_temp = distance_temp_diffsource(index);
                        route_temp = data_temp{index};
                        [ I_real_temp1, U_real_temp1 ] = real_IU_calculate( route_temp, I_real_temp2, U_real_temp2, P_load, U_rated, R, P_generate, eff );
                    else
                        index = tt;
                        capacity_trans_temp = I0_temp;
                        distance_temp = distance_temp_diffsource(index);
                        route_temp = data_temp{index};
                        [ I_real_temp1, U_real_temp1 ] = real_IU_calculate( route_temp, I_real_temp2, U_real_temp2, P_load, U_rated, R, P_generate, eff );
                    end
                end     
            else
                tt = find(distance_temp_diffsource==min(distance_temp_diffsource));  %%%%%范围扩大一下
                if length(tt)>1 % 超过一条最短路径，判断真实损耗
                    for k = 1:1:length(tt)
                        route_temp = data_temp{tt(k)};
                        [ I_real_temp3, U_real_temp3 ] = real_IU_calculate( route_temp, I_real_temp2, U_real_temp2, P_load, U_rated, R, P_generate, eff );
                        powerloss_temp(k) = sum(sum((I_real_temp3.^2.*R)));
                    end
                    index_temp = find(powerloss_temp==min(powerloss_temp));
                    if length(index_temp)>1
                        index = tt(index_temp(1));
                    else
                        index = tt(index_temp);
                    end
                    capacity_trans_temp = I0_temp;
                    distance_temp = distance_temp_diffsource(index);
                    route_temp = data_temp{index};
                    [ I_real_temp1, U_real_temp1 ] = real_IU_calculate( route_temp, I_real_temp2, U_real_temp2, P_load, U_rated, R, P_generate, eff );
                else
                    index = tt;
                    capacity_trans_temp = I0_temp;
                    distance_temp = distance_temp_diffsource(index);
                    route_temp = data_temp{index};
                    [ I_real_temp1, U_real_temp1 ] = real_IU_calculate( route_temp, I_real_temp2, U_real_temp2, P_load, U_rated, R, P_generate, eff );
                end
            end
        else
            % find the shortest path
            distance_temp_diffsource = [];
            
            for t=1:1:length(source_temp)
                if source_temp(t) > 0
                    [ distance_temp1, route_temp ] = ShortestPath( Map_temp, source_temp(t), destination );
                    data_temp{t}= route_temp;
                    distance_temp_diffsource(t) = distance_temp1;
                else
                    data_temp{t}= 'null';
                    distance_temp_diffsource(t) = inf;
                end
            end
            if min(distance_temp_diffsource) == Inf %没有满足条件的最短路径
                data{j}.capacity_trans = P_demand_temp;
                data{j}.distance = inf;
                data{j}.route = 'null';
                [ p_in, p_out ] = Power_flow( destination, I_real_temp2, U_real_temp2, U_rated );
                P_present = p_in *eff - p_out;
                P_load(destination) = P_present;
                break;
            else
                tt = find(distance_temp_diffsource==min(distance_temp_diffsource));  %%%%%范围扩大一下
                if length(tt)>1 % 超过一条最短路径，判断真实损耗
                    for k = 1:1:length(tt)
                        route_temp = data_temp{tt(k)};
                        [ I_real_temp3, U_real_temp3 ] = real_IU_calculate( route_temp, I_real_temp2, U_real_temp2, P_load, U_rated, R, P_generate, eff );
                        powerloss_temp(k) = sum(sum((I_real_temp3.^2.*R)));
                    end
                    index_temp = find(powerloss_temp==min(powerloss_temp));
                    if length(index_temp)>1
                        index = tt(index_temp(1));
                    else
                        index = tt(index_temp);
                    end
                    capacity_trans_temp = I0_temp;
                    distance_temp = distance_temp_diffsource(index);
                    route_temp = data_temp{index};
                    [ I_real_temp1, U_real_temp1 ] = real_IU_calculate( route_temp, I_real_temp2, U_real_temp2, P_load, U_rated, R, P_generate, eff );
                else
                    index = tt;
                    capacity_trans_temp = I0_temp;
                    distance_temp = distance_temp_diffsource(index);
                    route_temp = data_temp{index};
                    [ I_real_temp1, U_real_temp1 ] = real_IU_calculate( route_temp, I_real_temp2, U_real_temp2, P_load, U_rated, R, P_generate, eff );
                end
            end
        end
        
        % limitation
        select_source = route_temp(1);
        Status_source_temp1 = zeros(size(Capacity_source));
        for num_source = 1:1:length(source)
            source_point = source(num_source);
            [ p_in, p_out ] = Power_flow( source_point, I_real_temp1, U_real_temp1, U_rated );
            Status_source_temp1(source_point) = p_out/eff - p_in;
        end
        
        if select_source == destination % source = destination
            b = Capacity_source(select_source) - Status_source_temp1(select_source)- P_load(select_source)/eff;
            if b>=0
                I_real_temp2 = I_real_temp1;
                U_real_temp2 = U_real_temp1;
                data{j}.capacity_trans = P_demand_temp;
                data{j}.distance = distance_temp;
                data{j}.route = route_temp;
%                 P_generate(select_source) = P_demand_temp;
                [ p_in, p_out ] = Power_flow( select_source, I_real_temp2, U_real_temp2, U_rated );
                P_present = p_out/eff - p_in;
                P_generate(select_source) = P_present+P_load(select_source)/eff;

                flag = false;
            else
                
                Capacity_rest = Capacity_source(select_source) - Status_source_temp1(select_source);
                data{j}.capacity_trans = Capacity_rest*eff;
                data{j}.distance = distance_temp;
                data{j}.route = route_temp;
                P_generate(select_source) = Capacity_source(select_source);
                
                [ p_in, p_out ] = Power_flow( destination, I_real_temp2, U_real_temp2, U_rated );
                P_present = p_in *eff - p_out;
                P_demand_temp = P_load(destination) - P_present - P_generate(select_source)*eff;
                j = j+1;
            end
        else
            % source limitation
            b = Capacity_source(select_source) - Status_source_temp1(select_source)- P_load(select_source)/eff;
            if b >= 0 % source
                temp = [];
                compare = Capacity_line - I_real_temp1;
                for i=1:1:length(route_temp)-1
                    temp = [temp, compare(route_temp(i),route_temp(i+1))];
                end
                a = min(temp);
                if a >= 0 % line
                    I_real_temp2 = I_real_temp1;
                    U_real_temp2 = U_real_temp1;
                    data{j}.capacity_trans = P_demand_temp;
                    data{j}.distance = distance_temp;
                    data{j}.route = route_temp;

                    [ p_in, p_out ] = Power_flow( select_source, I_real_temp2, U_real_temp2, U_rated );
                    P_present = p_out/eff - p_in;
                    P_generate(select_source) = P_present+P_load(select_source)/eff;

                    flag = false;
                else
                    I_real_temp1 = I_real_temp2;
                    U_real_temp1 = U_real_temp2;
                    [m,n] = find(compare == a);
                    [x] = find(route_temp == m);
                    [y] = find(route_temp == n);
                    x = min(x);
                    y = min(y);
                    I_real_temp1(route_temp(x),route_temp(y)) = Capacity_line(route_temp(x),route_temp(y));
                    I_real_temp1(route_temp(y),route_temp(x)) = -I_real_temp1(route_temp(x),route_temp(y));
                    U_real_temp1(route_temp(x),route_temp(y)) = U_rated + I_real_temp1(route_temp(x),route_temp(y)) * R(route_temp(x),route_temp(y));
                    U_real_temp1(route_temp(y),route_temp(x)) = U_real_temp1(route_temp(x),route_temp(y));
                    route_temp_toStart = [];
                    route_temp_toFinish = [];
                    route_temp_toStart = route_temp(1:y);
                    route_temp_toFinish = route_temp(x:length(route_temp));
                    [ I_real_temp1, U_real_temp1 ] = real_IU_calculate_FtoS( route_temp_toStart, I_real_temp1, U_real_temp1, P_load, U_rated, R, P_generate, eff );
                    [ I_real_temp1, U_real_temp1 ] = real_IU_calculate_StoF( route_temp_toFinish, I_real_temp1, U_real_temp1, P_load, U_rated, R, P_generate, eff );
                    I_real_temp2 = I_real_temp1;
                    U_real_temp2 = U_real_temp1;

                    [ p_in, p_out ] = Power_flow( destination, I_real_temp2, U_real_temp2, U_rated );
                    P_present = p_in *eff - p_out;


                    data{j}.capacity_trans = P_demand_temp - (P_load(destination) - P_present);
                    data{j}.distance = distance_temp;
                    data{j}.route = route_temp;
                    P_demand_temp = P_load(destination) - P_present;

                    [ p_in, p_out ] = Power_flow( select_source, I_real_temp2, U_real_temp2, U_rated );
                    P_present = p_out/eff - p_in;
                    P_generate(select_source) = P_present + P_load(select_source)/eff;

                    j = j+1;
                end
            else % source max
                I_real_temp1 = I_real_temp2;
                U_real_temp1 = U_real_temp2;
                %
                P_present = 0;
                p_in = 0;
                p_out = 0;
                for k = 1:1:length(I_real_temp2(:,select_source)) %计算流出节点功率
                    if k ~= route_temp(2)
                        if I_real_temp2(k,select_source)>=0
                            p_in = p_in + I_real_temp2(k,select_source)* U_rated;
                        else
                            p_out = p_out - I_real_temp2(k,select_source)* U_real_temp2(k,select_source);
                        end
                    end
                end
                P_present = p_out/eff - p_in;

                Capacity_rest = Capacity_source(select_source) - P_present - P_load(select_source)/eff;
                % 电源和负载可能是同一个节点，capacity_rest可能为负
                if Capacity_rest>=0
                    I0_temp2 = (-U_rated+sqrt(U_rated^2+4*Capacity_rest*eff*R(select_source,route_temp(2))))/(2*R(select_source,route_temp(2)));
                    I_real_temp1(select_source,route_temp(2)) = I0_temp2;
                    I_real_temp1(route_temp(2),select_source) = -I_real_temp1(select_source,route_temp(2));
                    U_real_temp1(select_source,route_temp(2)) = U_rated + I0_temp2 * R(select_source,route_temp(2));
                    U_real_temp1(route_temp(2),select_source) = U_real_temp1(select_source,route_temp(2));
                    [ I_real_temp1, U_real_temp1 ] = real_IU_calculate_StoF( route_temp, I_real_temp1, U_real_temp1, P_load, U_rated, R, P_generate, eff );
                else
                    I0_temp2 = Capacity_rest*eff/U_rated;
                    I_real_temp1(select_source,route_temp(2)) = I0_temp2;
                    I_real_temp1(route_temp(2),select_source) = -I_real_temp1(select_source,route_temp(2));
                    U_real_temp1(select_source,route_temp(2)) = U_rated - I0_temp2 * R(select_source,route_temp(2));
                    U_real_temp1(route_temp(2),select_source) = U_real_temp1(select_source,route_temp(2));
                    [ I_real_temp1, U_real_temp1 ] = real_IU_calculate_StoF( route_temp, I_real_temp1, U_real_temp1, P_load, U_rated, R, P_generate, eff );
                end

                temp = [];
                compare = Capacity_line - I_real_temp1;
                for i=1:1:length(route_temp)-1
                    temp = [temp, compare(route_temp(i),route_temp(i+1))];
                end
                a = min(temp);
                if a >= 0
                    I_real_temp2 = I_real_temp1;
                    U_real_temp2 = U_real_temp1;

                    [ p_in, p_out ] = Power_flow( destination, I_real_temp2, U_real_temp2, U_rated );
                    P_present = p_in *eff - p_out;

                    data{j}.capacity_trans = P_demand_temp - (P_load(destination) - P_present);
                    data{j}.distance = distance_temp;
                    data{j}.route = route_temp;

                    P_demand_temp = P_load(destination) - P_present;

                    [ p_in, p_out ] = Power_flow( select_source, I_real_temp2, U_real_temp2, U_rated );
                    P_present = p_out/eff - p_in;
                    P_generate(select_source) = P_present + P_load(select_source)/eff;

                    j = j+1;
                else
                    I_real_temp1 = I_real_temp2;
                    U_real_temp1 = U_real_temp2;
                    [m,n] = find(compare == a);
                    [x] = find(route_temp == m);
                    [y] = find(route_temp == n);
                    x = min(x);
                    y = min(y);
                    I_real_temp1(route_temp(x),route_temp(y)) = Capacity_line(route_temp(x),route_temp(y));
                    I_real_temp1(route_temp(y),route_temp(x)) = -I_real_temp1(route_temp(x),route_temp(y));
                    U_real_temp1(route_temp(x),route_temp(y)) = U_rated + I_real_temp1(route_temp(x),route_temp(y)) * R(route_temp(x),route_temp(y));
                    U_real_temp1(route_temp(y),route_temp(x)) = U_real_temp1(route_temp(x),route_temp(y));
                    route_temp_toStart = [];
                    route_temp_toFinish = [];
                    route_temp_toStart = route_temp(1:y);
                    route_temp_toFinish = route_temp(x:length(route_temp));
                    [ I_real_temp1, U_real_temp1 ] = real_IU_calculate_FtoS( route_temp_toStart, I_real_temp1, U_real_temp1, P_load, U_rated, R, P_generate, eff);
                    [ I_real_temp1, U_real_temp1 ] = real_IU_calculate_StoF( route_temp_toFinish, I_real_temp1, U_real_temp1, P_load, U_rated, R, P_generate, eff);

                    I_real_temp2 = I_real_temp1;
                    U_real_temp2 = U_real_temp1;

                    [ p_in, p_out ] = Power_flow( destination, I_real_temp2, U_real_temp2, U_rated );
                    P_present = p_in *eff - p_out;

                    data{j}.capacity_trans = P_demand_temp - (P_load(destination) - P_present);
                    data{j}.distance = distance_temp;
                    data{j}.route = route_temp;
                    P_demand_temp = P_load(destination) - P_present;

                    [ p_in, p_out ] = Power_flow( select_source, I_real_temp2, U_real_temp2, U_rated );
                    P_present = p_out/eff - p_in;
                    P_generate(select_source) = P_present + P_load(select_source)/eff;

                    j = j+1;
                end
            end
        end
    end
    I_real = I_real_temp2;
    U_real = U_real_temp2;
end

