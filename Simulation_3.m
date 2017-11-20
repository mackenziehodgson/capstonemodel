% Author: Hazen S. Dean IV

%{
TODO:
* Add matrices or arrays that keep track of how state variables are
changing, as well as what the values for various metrics are
 - coalStored
 - NGConsumed
 - coalConsumed
 - temp
 - month
 - day
 - hour
* Add more states to capture more combinations of boilers for natural gas
and coal (e.g. 1 NG, 1 Coal; 1 NG, 2 Coal; 2 NG, 1 coal) --> Get the exact states that are
utilized from Paul, in order to better understand how things change in
real life. This further emphasizes the need to understand the actual
"rules" that are dictating the operations of the plant
* Incorporate ordering coal
* Consider incorporating a month or time object
* Add a temperature API


%}

% Variables defined

% Hour to capture the point in the 8760 model
step = 0;

coalStored = 1000000000.0; % get this from number of hours of coal storable
coalConsumed = 0.0;
NGConsumed = 0.0;
NGCap = 250000000.0;
temp = 0;

% Don't worry about actual demand yet
% heatDemand = 1;

% Don't worry about emissions yet
% emissions = 0.0;

% Don't worry about cost yet
% dollarCostNG = ;
% dollarCostCoal = ;

% Don't worry about specific seasonal allotment yet
% summerNGAllotment = ;
% double fallNGAllotment = ;
% double winterNGAllotment = ;
% double springNGAllotment = ;

% For now, we will assume that each month just has 30 days
% ... we can add complexity when we create month objects
% month = 1;
numMonths = 12;
% day = 1; // might not need this variable
%numDays = 30;
% numBoilers = 5; // might not need this variable
numBoilersOn = 0;
numBoilersOnCoal = 0;
numBoilersOnNG = 0;
NGEmissions = 0;
coalEmissions = 0;
NGCosts = 0;
coalCosts = 0;

coal = false;
NG = false;

monthlength = [1 31; 2 29; 3 31;4 30; 5 31;6 30; 7 31;8 31; 9 30; 10 31; 11 30; 12 31];
% Don't worry about placing orders yet
% waitingForCoalArrival = false;

% Temp thresholds that dictate the state
fourth = 69;
third = 20;
second = 5;
first = -5;

% Vectors for storing everything
boilersOnVec = NaN(8640, 1);
boilersOnCoalVec = NaN(8640, 1);
boilersOnNGVec = NaN(8640, 1);

% MAKE SURE THESE ARE RIGHT FOR BOOLEAN STORAGE

CoalOnVec = NaN(8640, 1);
NGOnVec = NaN(8640, 1);
SVec = NaN(8640, 1);
tempVec = NaN(8640, 1);

%{
The following loops encompass the 8760 model. Within the model:
    - The outermost loop captures months
    - The next inner loop captures days
    - The innermost loop captures the hours of each day
    - The first set of if statements accounts for a given temperature
        - From the temp, constraints then dictate what state may be
        achieved
    - Within the state, several things take place:
        - numBoilersOn is updated
        - numBoilersOnCoal is updated
        - numBoilersOnNG is updated
        - The amount of fuel consumed (as pertaining to the boilers in use
        under the given state) is incremented:
            - NGConsumed is incremented by numBoilersOnNG
            - coalConsumed is incremented by numBoilersOnCoal


%}

% Declare temperature distributions for each month

%janTemp = makedist('Normal','mu',35.19,'sigma',8.75);
%febTemp = makedist('Normal','mu',31.31,'sigma',15.62);
%marTemp = makedist('Normal','mu',50.95,'sigma',11.32);
%aprTemp = makedist('Normal','mu',60.39,'sigma',9.89);
%mayTemp = makedist('Normal','mu',69.07,'sigma',8.77);
%junTemp = makedist('Normal','mu',74.29,'sigma',5.70);
%julTemp = makedist('Normal','mu',74.45,'sigma',5.69);
%augTemp = makedist('Normal','mu',72.95,'sigma',6.28);
%sepTemp = makedist('Normal','mu',62.49,'sigma',7.99);
%octTemp = makedist('Normal','mu',55.40,'sigma',8.62);
%novTemp = makedist('Normal','mu',50.07,'sigma',9.30);
%decTemp = makedist('Normal','mu',50.52,'sigma',9.72);

tempmatrix = xlsread('/Users/mackenziee/Documents/Academics/Fourth Year/Capstone/tempdata.xlsx','model');

for i=1:numMonths
    numDays = monthlength(i,2);
    disp(numDays)
    for t=1:numDays
        
        % Get a temp for each day
        %if i == 1
              %  temp = random(janTemp);
            %elseif i == 2
           %  %   temp = random(febTemp);
           % elseif i == 3
             %   temp = random(marTemp);
           % elseif i == 4
             %   temp = random(aprTemp);
           % elseif i == 5
             %   temp = random(mayTemp);
           % elseif i == 6
              %  temp = random(junTemp);
           % elseif i == 7
               % temp = random(julTemp);
            %elseif i == 8
              %  temp = random(augTemp);
           % elseif i == 9
              %  temp = random(sepTemp);
          %  elseif i == 10
              %  temp = random(octTemp);
           % elseif i == 11
                %temp = random(novTemp);
            %elseif i == 12
               % temp = random(decTemp);
        %end
       
        for h=1:24
            
            % Increment the step
            step = step + 1;            
            temp = tempmatrix(step, 2);
            % Generate a small random number to change the temp by
            R = (.25)+(1.5)*rand(1,1);
            
            % Within each hour, change the temp slightly
            % for the first 12 hours, have it get warmer over the day
            % Then, have it get colder
            if h < 12
                temp = temp + R;
            elseif h > 12
                temp = temp - R;
            end
            
            % Determine how many boilers to turn on based on temp
            if temp > fourth
                % Don't burn anything
                % NOTE: This is a base state, and is likely not necessary
                % to include, as it is highly unlikely, and presumably
                % impossible, given the need for the heating plant to be
                % providing steam to the UVA hospital
                s=1;
                
            % Need 1
            elseif temp < fourth && temp > third
                % Turn on one natural gas burner
                if (NGConsumed < NGCap)
                    % If we have enough NG to turn on 1 boiler, do so
                    s = 2;
                elseif (coalStored > 0)
                    % Otherwise, if we have enough to turn on 1 coal, do so
                    s = 7;
                else
                    % Otherwise, we can't burn anything
                    s = 1;
                end
                    
            % Need 2
            elseif temp < third && temp > second
                % Turn on 2 NG boilers
                if (NGConsumed + 1 < NGCap)
                    % If we have enough NG to turn on 2 boilers, do so
                    s = 3;
                elseif (NGConsumed < NGCap && coalStored > 0)
                    % Otherwise, check for 1 NG, 1 Coal
                    s = 8;
                elseif (coalStored - 1 > 0)
                    % Otherwise, check for 2 Coal
                    s = 9;
                
                % CHECKS FOR 1 BOILER
                elseif (NGConsumed < NGCap)
                    % Otherwise, check for 1 NG
                    s = 2;
                elseif (coalStored > 0)
                    % Otherwise, check for 1 Coal
                    s = 7;
                else
                    % Otherwise, we can't burn anything
                    s = 1;
                end
                
            % Need 3
            elseif temp < second && temp > first
                % Turn on 3 NG boilers
                if (NGConsumed + 2 < NGCap)
                    % If we have enough NG to turn on 3 boilers, do so
                    s = 4;
                elseif (NGConsumed + 1 < NGCap && coalStored > 0)
                    % Otherwise, check for 2 NG, 1 Coal
                    s = 10;
                elseif (NGConsumed < NGCap && coalStored - 1 > 0)
                    % Otherwise, check for 1 NG, 2 Coal
                    s = 11;
                elseif (coalStored - 2 > 0)
                    % Otherwise, check for 3 Coal
                    s = 6;
                
                % CHECKS FOR 2 BOILERS
                elseif (NGConsumed + 1 < NGCap)
                    % Otherwise, check for 2 NG
                    s = 3;
                elseif (NGConsumed < NGCap && coalStored > 0)
                    % Otherwise, check for 1 NG, 1 Coal
                    s = 8;
                elseif (coalStored - 1 > 0)
                    % Otherwise, check for 2 Coal
                    s = 9;
                % CHECKS FOR 1 BOILER
                elseif (NGConsumed < NGCap)
                    % Otherwise, check for 1 NG
                    s = 2;
                 elseif (coalStored > 0)
                    % Otherwise, check for 1 Coal
                    s = 7;
                else
                    % Otherwise, we can't burn anything
                    s = 1;
                end
                
            % Need 4
            %{
            I am changing this elseif statement so that the lines of code
            within it are never executed. This will guarantee that we never
            use 4 boilers
            %}
            
            % elseif temp < second && temp > first
            %{
            elseif temp < 1000 && temp > 1000
                % Turn on 3 NG boilers, 1 Coal boiler
                if (NGConsumed + 2 < NGCap && coalStored > 0)
                    % If we have enough NG to turn on 3 boilers, and enough
                    % coal to turn on 1 boiler, do so
                    s = 5;
                elseif (NGConsumed + 1 < NGCap && coalStored - 1 > 0)
                    % Otherwise, check for 2 NG, 2 Coal
                    s = 12;
                    
                % CHECKS FOR 3 BOILERS
                elseif (NGConsumed + 2 < NGCap)
                    % If we have enough NG to turn on 3 boilers, do so
                    s = 4;
                elseif (NGConsumed + 1 < NGCap && coalStored > 0)
                    % Otherwise, check for 2 NG, 1 Coal
                    s = 10;
                elseif (NGConsumed < NGCap && coalStored - 1 > 0)
                    % Otherwise, check for 1 NG, 2 Coal
                    s = 11;
                elseif (coalStored - 2 > 0)
                    % Otherwise, check for 3 Coal
                    s = 6;
                % CHECKS FOR 2 BOILERS
                elseif (NGConsumed + 1 < NGCap)
                    % Otherwise, check for 2 NG
                    s = 3;
                elseif (NGConsumed < NGCap && coalStored > 0)
                    % Otherwise, check for 1 NG, 1 Coal
                    s = 8;
                elseif (coalStored - 1 > 0)
                    % Otherwise, check for 2 Coal
                    s = 9;
                % CHECKS FOR 1 BOILER 
                elseif (NGConsumed < NGCap)
                    % Otherwise, check for 1 NG
                    s = 2;
                elseif (coalStored > 0)
                    % Otherwise, check for 1 Coal
                    s = 7;
                else
                    % Otherwise, we can't burn anything
                    s = 1;
                end
            %}

            % We have reached the cutoff point for NG use, so we are no
            % longer able to utilize NG for the boilers
            elseif temp < first
                % The only thing we can do in this state is burn coal, so
                % we try to turn on 3 coal boilers, if we can
                elseif (coalStored - 2 > 0)
                    s = 6;
                elseif (coalStored - 1 > 0)
                    % Otherwise, check for 2 Coal
                    s = 9;
                elseif (coalStored > 0)
                    % Otherwise, check for 1 Coal
                    s = 7;
                else
                    % Otherwise, we can't burn anything
                    s = 1;                    
            end
             
            
            coalperhour = 5000;
            ngperhour =100000;
            coalemis = 7.15;
            ngemis = 5.855;
            coalcost = 100;
            ngcost = 142.857;
            
            % NULL STATE
            if s==1 % Boilers : 0 NG, 0 Coal
                numBoilersOn = 0;
                numBoilersOnCoal = 0;
                numBoilersOnNG = 0;
                coal = false;
                NG = false;
                
                
            elseif s==2 % Boilers : 1 NG, 0 Coal
                numBoilersOn = 1;
                numBoilersOnCoal = 0;
                numBoilersOnNG = 1;
                coal = false;
                NG = true;
                coalConsumed = coalConsumed + 0.0;
                NGConsumed = NGConsumed + ngperhour;
                NGEmissions = NGEmissions + ngemis;
                coalEmissions = coalEmissions + 0.0;
                NGCosts = NGCosts + ngcost;
                coalCosts = coalCosts + 0.0;
                
               
            elseif s==3 % Boilers : 2 NG, 0 Coal
                numBoilersOn = 2;
                numBoilersOnCoal = 0;
                numBoilersOnNG = 2;
                coal = false;
                NG = true;
                coalConsumed = coalConsumed + 0.0;
                NGConsumed = NGConsumed + 2*(coalperhour);
                NGEmissions = NGEmissions + 2*(ngemis);
                coalEmissions = coalEmissions + 0.0;
                NGCosts = NGCosts + 2*ngcost;
                coalCosts = coalCosts + 0.0;
                         
            elseif s==4 % Boilers : 3 NG, 0 Coal
                numBoilersOn = 3;
                numBoilersOnCoal = 0;
                numBoilersOnNG = 3;
                coal = false;
                NG = true;
                coalConsumed = coalConsumed + 0.0;
                NGConsumed = NGConsumed + 3*ngperhour;
                NGEmissions = NGEmissions + 3*ngemis;
                coalEmissions = coalEmissions + 0.0;
                NGCosts = NGCosts + 3*ngcost;
                coalCosts = coalCosts + 0.0;
               
            elseif s==5 % Boilers : 3 NG, 1 Coal
                numBoilersOn = 4;
                numBoilersOnCoal = 1;
                numBoilersOnNG = 3;
                coal = true;
                NG = true;
                coalStored = coalStored - 1.0*coalperhour;
                coalConsumed = coalConsumed + coalperhour;
                NGConsumed = NGConsumed + 3*ngperhour;
                NGEmissions = NGEmissions + 3*ngemis;
                coalEmissions = coalEmissions + coalemis;
                NGCosts = NGCosts + 3*ngcost;
                coalCosts = coalCosts + coalcost;
                
            elseif s==6 % Boilers : 0 NG, 3 Coal
                numBoilersOn = 3;
                numBoilersOnCoal = 3;
                numBoilersOnNG = 0;
                coal = true;
                NG = false;
                coalStored = coalStored - 3.0*coalperhour;
                coalConsumed = coalConsumed + 3*coalperhour;
                NGConsumed = NGConsumed + 0*ngperhour;
                NGEmissions = NGEmissions + 0*ngemis;
                coalEmissions = coalEmissions + 3*coalemis;
                NGCosts = NGCosts + 0*ngcost;
                coalCosts = coalCosts + 3*coalcost;
                
            elseif s==7 % Boilers : 0 NG, 1 Coal
                numBoilersOn = 1;
                numBoilersOnCoal = 1;
                numBoilersOnNG = 0;
                coal = true;
                NG = false;
                coalStored = coalStored - 1.0*coalperhour;
                coalConsumed = coalConsumed +coalperhour;
                NGConsumed = NGConsumed + 0.0;
                NGEmissions = NGEmissions + 0.0;
                coalEmissions = coalEmissions + coalemis;
                NGCosts = NGCosts + 0.0;
                coalCosts = coalCosts + coalcost;
                
            elseif s==8 % Boilers : 1 NG, 1 Coal
                numBoilersOn = 2;
                numBoilersOnCoal = 1;
                numBoilersOnNG = 1;
                coal = true;
                NG = true;
                coalStored = coalStored - 1.0*coalperhour;
                coalConsumed = coalConsumed + coalperhour;
                NGConsumed = NGConsumed + ngperhour;
                NGEmissions = NGEmissions + ngemis;
                coalEmissions = coalEmissions + coalemis;
                NGCosts = NGCosts + ngcost;
                coalCosts = coalCosts + coalcost;
                
            elseif s==9 % Boilers : 0 NG, 2 Coal
                numBoilersOn = 2;
                numBoilersOnCoal = 2;
                numBoilersOnNG = 0;
                coal = true;
                NG = false;
                coalStored = coalStored - 2.0*coalperhour;
                coalConsumed = coalConsumed + 2*coalperhour;
                NGConsumed = NGConsumed + 0.0;
                NGEmissions = NGEmissions + 0.0;
                coalEmissions = coalEmissions + 2.0*coalemis;
                NGCosts = NGCosts + 0.0;
                coalCosts = coalCosts + 2.0*coalcost;
                
            elseif s==10 % Boilers : 2 NG, 1 Coal
                numBoilersOn = 3;
                numBoilersOnCoal = 1;
                numBoilersOnNG = 2;
                coal = true;
                NG = true;
                coalStored = coalStored - 1.0*coalperhour;
                coalConsumed = coalConsumed + 1.0*coalperhour;
                NGConsumed = NGConsumed + 2.0*ngperhour;
                NGEmissions = NGEmissions + 2*ngemis;
                coalEmissions = coalEmissions + 1.0*coalemis;
                NGCosts = NGCosts + 2.0*ngcost;
                coalCosts = coalCosts + 1.0*coalcost;
                
            elseif s==11 % Boilers : 1 NG, 2 Coal
                numBoilersOn = 3;
                numBoilersOnCoal = 2;
                numBoilersOnNG = 1;
                coal = true;
                NG = true;
                coalStored = coalStored - 2.0*coalperhour;
                coalConsumed = coalConsumed + 2.0*coalperhour;
                NGConsumed = NGConsumed + 1.0*ngperhour;
                NGEmissions = NGEmissions + 1.0*ngemis;
                coalEmissions = coalEmissions + 2.0*coalemis;
                NGCosts = NGCosts + 1.0*ngcost;
                coalCosts = coalCosts + 2.0*coalcost;
                
            elseif s==12 % Boilers : 2 NG, 2 Coal
                numBoilersOn = 4;
                numBoilersOnCoal = 2;
                numBoilersOnNG = 2;
                coal = true;
                NG = true;
                coalStored = coalStored - 2.0*coalperhour;
                coalConsumed = coalConsumed + 2.0*coalperhour;
                NGConsumed = NGConsumed + 2.0*ngperhour;
                NGEmissions = NGEmissions + 2.0*ngemis;
                coalEmissions = coalEmissions + 2.0*coalemis;
                NGCosts = NGCosts + 2.0*ngcost;
                coalCosts = coalCosts + 2.0*coalcost;
                
            elseif s==13 % Boilers : 1 NG, 3 Coal
                numBoilersOn = 4;
                numBoilersOnCoal = 3;
                numBoilersOnNG = 1;
                coal = true;
                NG = true;
                coalStored = coalStored - 3.0*coalperhour;
                coalConsumed = coalConsumed + 3*coalperhour;
                NGConsumed = NGConsumed + 1*ngperhour;
                NGEmissions = NGEmissions + 1*ngemis;
                coalEmissions = coalEmissions + 3*coalemis;
                NGCosts = NGCosts + 1*ngcost;
                coalCosts = coalCosts + 3*coalcost;
                
            end
            
            % Update vectors
            boilersOnVec(step, 1) = numBoilersOn;
            boilersOnCoalVec(step, 1) = numBoilersOnCoal;
            boilersOnNGVec(step, 1) = numBoilersOnNG;
            CoalOnVec(step, 1) = coal;
            NGOnVec(step, 1) = NG;
            SVec(step, 1) = s;
            tempVec(step, 1) = temp;
            
        end
    end    
end
T = table(boilersOnCoalVec,boilersOnNGVec,boilersOnVec,CoalOnVec, NGOnVec,SVec, tempmatrix);
filename = 'fuel_data_from_sim.xlsx';
writetable(T,filename,'Sheet',1)
file2 = 'more_fuel_data_from_sim.csv';
Value = [ coalConsumed;  coalCosts;  coalEmissions;  coalStored;  NGConsumed;  NGEmissions; NGCosts];
Index = { 'coal consumed';  'coal cost';  'coal emissions';  'coal stored';  'ng consumed';  'emissions';'ng emissions'};
table2 = table(Index, Value);
writetable(table2, filename, 'Sheet',2);

