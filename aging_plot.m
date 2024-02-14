clc; 
clear; 
close all;

% 폴더 경로 설정
folder_path{1} = '/Users/g.park/Library/CloudStorage/GoogleDrive-gspark@kentech.ac.kr/공유 드라이브/BSL_Data2/HNE_AgingDOE_processed/Experiment_data/Combined/CellID_6';
folder_path{2} = '/Users/g.park/Library/CloudStorage/GoogleDrive-gspark@kentech.ac.kr/공유 드라이브/BSL_Data2/HNE_AgingDOE_processed/Experiment_data/Combined/CellID_43';
folder_path{3} = '/Users/g.park/Library/CloudStorage/GoogleDrive-gspark@kentech.ac.kr/공유 드라이브/BSL_Data2/HNE_AgingDOE_processed/Experiment_data/Combined/CellID_97';

% 파일 목록을 저장할 배열 선언
file_names = cell(length(folder_path), 1);

% 각 폴더에 있는 파일 정보 가져오기
for i = 1:length(folder_path)
    % 해당 폴더의 파일 정보를 가져와서 data 변수에 저장
    data = dir(fullfile(folder_path{i}));

    % 파일 이름만 추출하여 배열에 저장
    file_names{i} = {data.name}';
end

% 결과를 저장할 셀 배열 선언
results = cell(length(folder_path), 1);

% 파일 로드 및 처리
for i = 1:length(folder_path)
    % 결과를 저장할 구조체 배열 초기화
    results{i} = struct('Q', {}, 'I', {}, 'cycle', {}, 'time', {}, 'cumT', {});
    
    % 파일 로드 및 처리
    for j = 1:length(file_names{i})
        % 파일 이름 가져오기
        file_name = file_names{i}{j};

        % 파일 경로 생성
        file_path = fullfile(folder_path{i}, file_name);

        % .mat 파일인 경우에만 로드하고 처리
        if endsWith(file_name, '.mat')  
            % .mat 파일 로드
            loaded_data = load(file_path);  

            % 필드 이름 가져오기
            fieldNames = fieldnames(loaded_data);

            % 필드별로 처리
            for k = 1:length(fieldNames)
                % 현재 필드의 이름
                currentField = fieldNames{k};

                % 필드가 구조체인 경우에만 처리
                if isstruct(loaded_data.(currentField))
                    % 'data' 필드를 가지고 있는 경우에만 처리
                    if isfield(loaded_data.(currentField), 'data')
                        % 'type' 필드가 있는 경우에만 처리
                        if isfield(loaded_data.(currentField).data, 'type')
                            % 'type'이 'D'인 경우에만 처리
                            indices = strcmp({loaded_data.(currentField).data.type}, 'D');

                            % 해당 인덱스에 해당하는 값을 가져와서 셀 배열에 저장
                            Dcap = loaded_data.(currentField).data(indices);

                            cumT = 0;

                            % 파일별로 구분해서 Q, I, cycle 값을 저장
                            for m = 1:length(Dcap)
                                Q = abs(trapz(Dcap(m).t, Dcap(m).I)) / 3600;
                                I = Dcap(m).I;
                                cycle = Dcap(m).cycle;
                                t = Dcap(m).steptime;

                                if isduration(t)
                                    cumT = cumT + seconds(t(end));
                                else
                                    cumT = cumT + t(end);
                                end

                                results{i}(end+1) = struct('Q', Q, 'I', I, 'cycle', cycle, 'time', t(end)/3600, 'cumT', cumT/3600);
                            end
                        end
                    end
                end


            end
        else
            disp(['Unsupported file format: ' file_name]);  % 지원되지 않는 파일 형식인 경우 메시지 출력
        end
    end



end

% 사이클 번호 업데이트 로직 수정
for i = 1:length(results)
    updated_results = []; % 수정된 결과를 저장할 임시 배열
    cycle_counter = 1; % 'cycle' 1부터 시작
    last_cycle_was_one = false; % 마지막 사이클이 '1'인지 추적

    for j = 1:length(results{i})
        if results{i}(j).cycle == 1
            % '1' 사이클 발견 시, 마지막 '1'만 남기기 위해 기록만 하고 추가는 하지 않음
            if last_cycle_was_one
                % 이미 '1' 사이클 중이면 이전 '1' 사이클을 제거하고 최신 것으로 대체
                updated_results(end) = results{i}(j); % 마지막 '1'을 현재 '1'으로 업데이트
            else
                updated_results = [updated_results, results{i}(j)]; % 첫 '1' 사이클을 추가
                last_cycle_was_one = true; % '1' 사이클 시작 표시
            end
        else
            if last_cycle_was_one
                % '1' 사이클 그룹이 끝나고 새 사이클이 시작됨
                cycle_counter = cycle_counter + 1; % '1' 사이클 그룹 이후 사이클 번호 증가
                last_cycle_was_one = false; % '1' 사이클 종료 표시
            end
            % 현재 사이클 번호 할당 및 결과 배열에 추가
            results{i}(j).cycle = cycle_counter;
            updated_results = [updated_results, results{i}(j)];
            cycle_counter = cycle_counter + 1; % 사이클 번호 증가
        end
    
    end
    results{i} = updated_results; % 최종 업데이트된 결과 배열로 대체
   
end



% 사이클 번호 업데이트 로직 수정 후

% 결과를 저장할 구조체 또는 셀 배열 초기화
Q_values_all = cell(length(folder_path), 1); % 각 폴더별 Q_values 저장
Q_values_normalized_all = cell(length(folder_path), 1); % 각 폴더별 Q_values_normalized 저장

% 사이클 번호 업데이트 로직 수정 후

% Q_values와 Q_values_normalized 계산 및 저장
for i = 1:length(results)
    % 각 결과에서 Q 값을 추출하여 벡터로 구성
    Q_values = arrayfun(@(x) x.Q, results{i});

    % Q_values를 첫 번째 원소로 정규화
    Q_values_normalized = Q_values / Q_values(1);

    % 계산된 값들을 저장
    Q_values_all{i} = Q_values;
    Q_values_normalized_all{i} = Q_values_normalized;
end

% 저장된 값들을 출력하거나 다른 작업을 수행
for i = 1:length(Q_values_normalized_all)
    disp(['Folder ', num2str(i), ': ', mat2str(Q_values_normalized_all{i})]);
end



% 
% 하나의 그래프에 모든 폴더의 Q_values_normalized 값을 플롯
% figure; % 새로운 그래프 창 생성
% hold on; % 여러 데이터 세트를 같은 그래프에 플롯하기 위해 hold on 사용
% 
% 각 폴더별 색상 설정
% colors = ['k', 'r', 'b']; % 검정, 빨강, 파랑
% 
% 각 폴더의 데이터 플롯
% for i = 1:length(folder_path)
%     해당 폴더의 Q_values_normalized 값 가져오기
%     Q_values_normalized = Qval{i}.Q_values_normalized;
% 
%     인덱스를 x축 값으로 사용
%     x_values = 1:length(Q_values_normalized);
% 
%     첫 번째 파일명을 레전드 이름으로 사용
%     legendName = sprintf('File: %s', file_names{i}{1});
% 
%     데이터 플롯 - 지정된 색상과 레전드 이름 사용
%     plot(x_values, Q_values_normalized, 'o-', 'Color', colors(i), 'DisplayName', legendName);
% end
% 
% 그래프 설정
% xlabel('Index');
% ylabel('Normalized Q values');
% title('Normalized Q values for Each Folder with File Names');
% legend('show'); % 범례 표시
% grid on; % 그리드 켜기
% hold off; % 플롯 추가 완료



% 색상 지정
colors = ['k', 'r', 'b']; % 검정, 빨강, 파랑 순서

% 새로운 그림 생성
figure;
hold on; % 여러 데이터를 한 그래프에 표시

% 각 폴더별로 스캐터 플롯 생성
for i = 1:length(Q_values_normalized_all)
    % 현재 폴더의 정규화된 Q 값을 가져옴
    Q_norm = Q_values_normalized_all{i};
    
    % 스캐터 플롯 그리기
    scatter(1:length(Q_norm), Q_norm, colors(i), 'DisplayName', extractAfter(folder_path{i}, 'Combined/'));
end


% 레전드 설정
legend('show');
xlabel('Cycle (n)');
ylabel('Cap / Cap0');
title('4CPD 1C V2542'); % 그래프 제목
ylim([0 1.4]);

hold off; % 그리기 종료

customsettings;






