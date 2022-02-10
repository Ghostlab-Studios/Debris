function [Contractor] = Repair_profit(Contractor, q_p,edge_change, TimeMatrix, profit_vec,...
    revenue_per_debris, capacity,depot, gas_per_distance,time_vec)

no_edges = size(edge_change,1);
change_check = true(no_edges,1);
%all_edges = (1:no_edges)';
%Contractor_original = Contractor;

updated_profit_vec = profit_vec;
q_t = mean(time_vec);
updated_time_vec = time_vec;

while all(change_check) == 1 
    
    %until you know all the selected trips are modified
    for t = 1: size(edge_change,1)
        from = edge_change(t,1); to = edge_change(t,2);
        nc = edge_change(t,3); %contractor
        cl = edge_change(t,4); %cluster
        tr = edge_change(t,5); %trip
        coll_debris = edge_change(t,6);
        %profit_of_nc = Contractor{nc}.TotalProfit; %contractor's profit

        if updated_profit_vec(nc) >= q_p
            change_check(t)=0;
            %To give the high profits contractors profit to the lower ones
           %Very similar to the idea in repair_time
           [Contractor, change_check, updated_profit_vec] = distributeTrip_profit(Contractor, nc, from, to,coll_debris, ...
               TimeMatrix, updated_profit_vec, revenue_per_debris, change_check,  gas_per_distance, depot, capacity);
        end
    end
    
    %If there are still trips that are not subject to change
    %Those trips are of contractors with small profit 
    % collect debris from the outer region of the cluster
    fi = find(change_check ==1);
    if isempty(fi) ~= 1
        for f = fi'
            nc = edge_change(f,3); cl = edge_change(f,4); tr = edge_change(f,5);
%             if updated_profit_vec(nc) <= q_p            
%             nodes = unique(Contractor{nc}.trips{1,cl}{tr,1}); %nodes on that trip
%             f_shared_nodes = node_intersection(nc, nodes) > 0; %find shared nodes bu other contractors
%             shared_nodes = nodes(f_shared_nodes); 
%             % try to find edges which's debris is collected by other
%             % contractors - and steal that debris 
%             profit_check = true;
%             [Contractor,updated_profit_vec] = stealDebris(Contractor, nc, cl, tr, shared_nodes, updated_profit_vec, TimeMatrix, capacity,revenue_per_debris, profit_check,depot,gas_per_distance);
%             end
            change_check(f) = 0;
        end
    end
    
end


end

