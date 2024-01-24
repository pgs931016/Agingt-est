


clc; clear; close all;


dirPath{1} = '/Users/g.park/Library/CloudStorage/GoogleDrive-gspark@kentech.ac.kr/공유 드라이브/BSL-Data/Processed_data/Hyundai_dataset/AgingDOE_cycle1/AgingDOE1/열화인자조합(16)/HNE_FCC_4CPD_0_5C_V2542_231121_cyc/20231127';
dirPath{2} = '/Users/g.park/Library/CloudStorage/GoogleDrive-gspark@kentech.ac.kr/공유 드라이브/BSL-Data/Processed_data/Hyundai_dataset/AgingDOE_cycle2/AgingDOE2/열화인자조합(16)/HNE_FCC_4CPD_0_5C_V2542_231121_cyc/20231221';
% Initialize a structure to store data
dataStruct = struct();

for i = 1:length(dirPath)
    files = dir(fullfile(dirPath{i}, '*mat'));
    
    for j = 1:length(files)
        filePath = fullfile(dirPath{i}, files(j).name);
        
        pattern = '(\d+).mat';
        match = regexp(files(j).name, pattern, 'match');
        
        if ~isempty(match)
            % Convert the matched numeric part to a number
            numericPart = str2double(match{1}(1:end-4)); 

            % Modify the numericPart to create a valid field name
            fieldName = ['CH', num2str(numericPart)];  
            fieldName = matlab.lang.makeValidName(fieldName);
            % Check if the field with the numeric part exists in the structure
            if isfield(dataStruct, fieldName)
                % If it exists, append the data along rows
                dataStruct.(fieldName) = [dataStruct.(fieldName); load(filePath)];
            else
                % If it doesn't exist, create a new field and store the data
                dataStruct.(fieldName) = load(filePath);
            end
        end
    end
end


% Get the list of unique field names in the structure
fieldNames = unique(fieldnames(dataStruct));

% Initialize a structure to store combined data
combinedDataStruct = struct();

for i = 1:length(fieldNames)
    currentField = fieldNames{i};
    
    if isfield(dataStruct, currentField) && isstruct(dataStruct.(currentField)) && numel(dataStruct.(currentField)) == 2
        fieldsStruct1 = dataStruct.(currentField)(1);
        fieldsStruct2 = dataStruct.(currentField)(2);
        
        combinedValues = struct();
        fieldNamesStruct1 = fieldnames(fieldsStruct1);
        
        for j = 1:length(fieldNamesStruct1)
            fieldName = fieldNamesStruct1{j};
            
            % 두 구조체의 값을 행 방향으로 연결
            combinedValues.(fieldName) = [fieldsStruct1.(fieldName)(1:end-1); fieldsStruct2.(fieldName)(1:end-1)];
                
        end
        
        % 결합된 값을 새로운 구조체에 할당
      combinedDataStruct.(currentField) = combinedValues;
    end
end


% Initialize a cell array to store extracted data
obj = cell(1, length(fieldNames));

for j = 1:length(fieldNames)
    % 현재 필드의 이름을 가져오기
    currentField = fieldNames{j};
    
    % 해당 필드가 구조체를 가지고 있으면서 그 구조체의 필드 중 'data'를 포함하고 있으면 처리
    if isfield(combinedDataStruct, currentField) && isfield(combinedDataStruct.(currentField), 'data')
        % 'type' 필드가 있는 경우에만 처리
        if isfield(combinedDataStruct.(currentField).data, 'type')
            indices = find(strcmp({combinedDataStruct.(currentField).data.type}, 'D'));

            % 해당 인덱스에 해당하는 값을 가져와서 셀 배열에 저장
            Dcap = combinedDataStruct.(currentField).data(indices);
            
            cumT = 0;
         
            % 파일별로 구분해서 Q, I, cycle 값을 저장
            result = struct('Q', {}, 'I', {}, 'cycle', {}, 'time', {}, 'cumT', {});

            for k = 1:length(Dcap)
                Q = abs(trapz(Dcap(k).t, Dcap(k).I)) / 3600;
                I = Dcap(k).I;
                cycle = Dcap(k).cycle;
                t = Dcap(k).steptime;
                % duration 형식인 경우 초로 변환
if isduration(t)
    cumT = cumT + seconds(t(end));
else
    % duration이 아닌 경우 그대로 사용
    cumT = cumT + t(end);
end
                

                % 구조체에 Q, I, cycle 값을 저장
                result(end+1) = struct('Q', Q, 'I', I, 'cycle', cycle, 'time', t(end)/3600, 'cumT', cumT/3600);
               
            end
        end        
   
   end
  obj{j} = result;  
end



for k = 1:length(obj)
    % obj의 각 요소는 구조체 배열
    currentStructArray = obj{1, k};
    
    % 각 구조체의 Q 필드를 추출하여 배열로 저장
    Q_values = arrayfun(@(x) x.Q, currentStructArray);  % 수정된 부분


    
    % 각 구조체의 cycle 필드를 추출하여 배열로 저장
    cycle_values = arrayfun(@(x) x.cycle, currentStructArray);
    
    % Scatter plot 그리기 (파란색)
    figure;
    scatter(1:length(cycle_values), (Q_values(k) / Q_values(1)), 'b');
    
    xlabel('Cycle (n)');
    ylabel('Cap / Cap0');
    title(['1CPD(2.5 - 4.2V), 0.5C ' fieldNames{k}]);

    ylim([0 1.4]);
    yticks(0:0.2:1.4);
    customsettings;
    hold on;

    % Scatter plot 그리기 (빨간색)
    figure;
    scatter(arrayfun(@(x) x.cumT, currentStructArray), (Q_values(k) / Q_values(1)), 'r');

    xlabel('Time (h)');
    ylabel('Cap / Cap0');
    title(['1CPD(2.5 - 4.2V), 0.5C, ' fieldNames{k}]);

    ylim([0 1.4]);
    yticks(0:0.2:1.4);
    customsettings;
    hold on;
end