
%This loops through the repair solution with different objectives




% After user makes the changes - repair algorithm

clc
clear

%[time, profit, intersection]
obj_category={[1,0,0],[1,0,1], [0,0,1],[0,1,0], [0,1,1],[1,1,0],[1,1,1]};
obj_cat_name= ['Time', 'Time + Int', 'Int', 'Profit', 'Profit+Int', 'Profit+Time', 'Profit+Time+Int'];
for o = 1:6 %There are a total of 7 combinations of objectives
    oo = obj_category{o};
    time_selected = oo(1);
    profit_selected = oo(2);
    intersection_selected = oo(3);

load('Contractor.mat') % indicates the previously given solution to the user that the user is goint to play with
load('ProblemData4.mat') %The problem data that is never going to change
load('Regions.mat')

load('brushed_edges.mat') % from, to , new_nc(as a list)

%Get a profit and time vec to see the relative difference of contractor's
%values
profit_vec=zeros(1,no_contractor);
time_vec=zeros(1,no_contractor);

for i=1:no_contractor
    profit_vec(i) = Contractor{i}.TotalProfit;
    time_vec(i) = Contractor{i}.TotalTime;
end


% newCoord = zeros(no_nodes,2);
% for coord = 1:no_nodes
%     lat = Coordinates(coord,2);
%     lon = Coordinates(coord,1);
%     alt=0;
%     [x,y]=getCartesianCoord(lat,lon,alt);
%     newCoord(coord,2)=x; newCoord(coord,1)=y;
% end

EdgeListMatrix = GenerateEdgeList( Contractor );


%edges are brushed based on their debris allocations
%When human assigns a cont on an edge it automatically divides the debris
%on the edge. If computer is asked to repair based on an objective than you
%can see only traversing contractors on edges

% obj_selected = [1, 0 , 0]; %Time- Profit-Intersection selections indicated with 1 if selected
% [Contractor] = fixBrushingErasing(EdgeListMatrix, Contractor, brushed_edges, obj_selected, time_vec, ...
%            profit_vec, Time, time_per_debris, revenue_per_debris, gas_per_distance, capacity, depot);


%%%%%%%%%%%%%%%%%%%%%

[ surrounding ] = findSurrounding( Contractor );
[Contractor,  node_intersection_matrix] = ComputeIntersection2(Contractor, depot, surrounding);
OVERLAP1 = sum(sum(node_intersection_matrix)); %The total overlap

par1 = 0.1 ; par2=0.1; %The explanation of these parameters are inside the following function
[Contractor, BadCycles_profit, BadCycles_intersection] = detectBadTrips(Contractor, capacity, par1, par2);


%%Detecting bad edges
%par3 is the threshold parameter
par3 = 0.25;
[ BadEdges ] = detectBadEdges( EdgeListMatrix, Contractor, par3, EdgeList );

%NEW!!! Detecting bad regions
%Assume that several regions are given with node numbers
%[ BadRegions_time, BadRegions_profit, BadRegions_intersection ] = detectBadRegions( regions, Contractor );

%trip_id is just the matrix the user decides to delete
%I assumed he decides to delete all the 'bad' cycles we provide him in
%terms of profit/time
%What kind of bad cycles to provide is a matter of questions
trip_id = BadCycles_profit;

%% Convert the trip_id to edge matrix
%So that you would have the same data structure
%edge change are the edges that will be transfered
[ edge_change ] = triptoEdge( Contractor, trip_id );


%this is the previous dijkstra we had - nothing changed
NODES=1:no_nodes;
[distLabel, pred]=dijkstra(Time, depot, NODES);



%Objectives:
% Min MAXTIME
% Max MINPROFIT
MAXTIME1= max(time_vec);
MINPROFIT1 = min(profit_vec);
%OBJ = char('Time' ,'Profit', 'Intersection');
%10 replications on the game playing
%User deletes cycles and we repair/improve the perturbed solution, give
%another set of candidate bad cycles he deletes again....

OVERLAP_VEC = OVERLAP1;
TIME_VEC= MAXTIME1;
PROFIT_VEC = MINPROFIT1;



    
    for replication = 1:20
        %The options user can select the solution to be improved
        %For now I defined it by hand - but this part is going to be decided by
        %the human
        %Which options he picks for the algorithm to improve?
        
        %Considering the trip_id is the set of cycles(trips) deleted by
        %repair solution based on the objectives to be improved defined by user
        [Contractor,predicted_improvement] = RepairSolution(Contractor, time_vec, profit_vec, edge_change, time_selected, ...
            profit_selected, intersection_selected, Time, time_per_debris, revenue_per_debris, ...
            gas_per_distance, capacity, depot);
        
        
        %For the re-assigned regions for each contractor, we reconstruct
        %Contractor data
        [Contractor] = ReconstructContractor(Contractor, distLabel,pred,...
            time_per_debris, revenue_per_debris, gas_per_distance,depot,capacity,Time);
        
        %In order to find the new ratios for intersection, calculate the
        %surrounding info on the updated solution
        [ surrounding ] = findSurrounding( Contractor );
        [Contractor,  node_intersection_matrix] = ComputeIntersection2(Contractor, depot, surrounding);
        OVERLAP2 = sum(sum(node_intersection_matrix));
        
        
        profit_vec=zeros(1,no_contractor);
        time_vec=zeros(1,no_contractor);
        
        for i=1:no_contractor
            profit_vec(i) = Contractor{i}.TotalProfit;
            time_vec(i) = Contractor{i}.TotalTime;
        end
        
        %time and profit updated for the current iteration
        [MAXTIME2, contmaxtime]= max(time_vec);
        [MINPROFIT2, contminprofit] = min(profit_vec);
        
        %I just wanted to see how much improvement in minprofit and maxtime it makes
        %Its just for me to see, if you want you can discard this part
        fprintf('Iteration: %d \n',replication);
        %fprintf('Selected Objectives: %s \n ',OBJ(obj_bool,:));
        fprintf('Predicted Improvement: %d \n', predicted_improvement);
        fprintf('Intersection: %f, \t Improvement: %f \n',OVERLAP2, OVERLAP1-OVERLAP2);
        fprintf('Completion Time: %f, \t Improvement: %f, \t Contractor(max_time): %f \n',MAXTIME2, MAXTIME1-MAXTIME2, contmaxtime);
        fprintf('Min Profit: %f, \t Improvement: %f, \t Contractor(min_profit): %f \n',MINPROFIT2, MINPROFIT1-MINPROFIT2, contminprofit);
        
        OVERLAP_VEC = [OVERLAP_VEC,OVERLAP2];
        TIME_VEC=[TIME_VEC, MAXTIME2];
        PROFIT_VEC=[PROFIT_VEC, MINPROFIT2];
        
        OVERLAP1 = OVERLAP2;
        MAXTIME1 = MAXTIME2;
        MINPROFIT1 = MINPROFIT2;
        
        %Get the new bad trips to improve in the next iteration
        [Contractor, BadCycles_profit, BadCycles_intersection] = detectBadTrips(Contractor, capacity, par1,par2);
        trip_id = BadCycles_profit;
        [ edge_change ] = triptoEdge( Contractor, trip_id );
        
    end
    
    Rep(o).profit = PROFIT_VEC;
    Rep(o).time = TIME_VEC;
    Rep(o).int = OVERLAP_VEC;
    
    
end

figure 
hold on 

for o=1:6
    plot(1:21, Rep(o).profit,'-*','DisplayName',obj_cat_name(o),'Color',rand(1,3))    
end
title('Change in Profit wrt different repair objs')
xlabel('Iteration')
ylabel('Objectives')
legend('show')
hold off

% figure
% hold on
% %plot( 1:4,TIME_VEC,'-*')
% %plot(1:4,OVERLAP_VEC.*100,'-*','color','r')
% plot(1:21,TIME_VEC,'-*',1:21,PROFIT_VEC,'-*')
% title('Improvement based on Profit + Time')
% xlabel('Iteration')
% ylabel('Objectives')
% hold off
%
% legend('Time', 'Profit')%, 'Intersection')
%
% %--------------%
% figure
% hold on
% plot(1:21,OVERLAP_VEC,'-*','color','r')
% title('Improvement based on Profit + Time')
% xlabel('Iteration')
% ylabel('Overlap Objective')
% hold off
%
% [ob1 , i ]= max(PROFIT_VEC);
% ob2 = TIME_VEC(i);
% ob3 = OVERLAP_VEC(i);
