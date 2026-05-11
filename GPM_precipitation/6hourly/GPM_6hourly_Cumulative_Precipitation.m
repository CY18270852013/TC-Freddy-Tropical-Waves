% GPM半小时降水数据转6小时累积降水数据
% 数据时间范围：2009-01-01 到 2023-12-31

clear;
clc;

% 设置路径
inputPath = '\\DS1821\Observation\GPM';
outputPath = 'E:\Results_of_Freddy_ChenYong_version2\GPM_6hourly_20090101_20231231';

% 创建输出目录
if ~exist(outputPath, 'dir')
    mkdir(outputPath);
    fprintf('创建输出目录: %s\n', outputPath);
end

% 定义时间范围
startDate = datetime(2009, 1, 1);
endDate = datetime(2023, 12, 31);

% 获取所有HDF5文件列表
fileList = dir(fullfile(inputPath, '*.HDF5'));
fileNames = {fileList.name};
fprintf('找到 %d 个HDF5文件\n', length(fileNames));

% 筛选出GPM降水数据文件并提取时间信息
gpmFiles = {};
fileDatetimes = datetime.empty;

fprintf('筛选文件并提取时间信息...\n');
for i = 1:length(fileNames)
    fileName = fileNames{i};
    
    % 检查文件名是否符合GPM降水数据文件命名规则
    if contains(fileName, '3B-HHR.MS.MRG.3IMERG') && ...
       contains(fileName, '-S') && contains(fileName, '-E')
        
        % 从文件名中提取日期和时间信息
        parts = strsplit(fileName, '.');
        if length(parts) >= 6
            datePart = parts{5};
            dateTimeParts = strsplit(datePart, '-');
            
            if length(dateTimeParts) >= 3
                dateStr = dateTimeParts{1};
                startTimeStr = dateTimeParts{2}(2:end); % 去掉'S'前缀
                
                % 验证日期和时间格式
                if length(dateStr) == 8 && length(startTimeStr) == 6
                    % 构建datetime对象
                    yearStr = dateStr(1:4);
                    monthStr = dateStr(5:6);
                    dayStr = dateStr(7:8);
                    
                    hourStr = startTimeStr(1:2);
                    minuteStr = startTimeStr(3:4);
                    secondStr = startTimeStr(5:6);
                    
                    fileDatetime = datetime(str2double(yearStr), str2double(monthStr), ...
                                           str2double(dayStr), str2double(hourStr), ...
                                           str2double(minuteStr), str2double(secondStr));
                    
                    % 检查日期是否在指定范围内
                    if fileDatetime >= startDate && fileDatetime <= endDate
                        gpmFiles{end+1} = fileName;
                        fileDatetimes(end+1) = fileDatetime;
                    end
                end
            end
        end
    end
end

fprintf('筛选出 %d 个在指定时间范围内的GPM降水数据文件\n', length(gpmFiles));

% 按时间排序
[fileDatetimes, sortIdx] = sort(fileDatetimes);
gpmFiles = gpmFiles(sortIdx);

% 定义6小时时段并分组
fprintf('开始按6小时时段分组...\n');
sixHourGroups = {};
currentGroup = [];
currentDate = NaT; % Not-a-Time
currentHourGroup = -1;

for i = 1:length(fileDatetimes)
    currentTime = fileDatetimes(i);
    currentHourValue = hour(currentTime);
    
    % 确定当前时间属于哪个6小时时段 (0-5, 6-11, 12-17, 18-23)
    if currentHourValue >= 0 && currentHourValue < 6
        hourGroup = 0;
    elseif currentHourValue >= 6 && currentHourValue < 12
        hourGroup = 6;
    elseif currentHourValue >= 12 && currentHourValue < 18
        hourGroup = 12;
    else
        hourGroup = 18;
    end
    
    % 如果是新的一组或第一组
    if isempty(currentGroup) || ...
       currentDate ~= dateshift(currentTime, 'start', 'day') || ...
       hourGroup ~= currentHourGroup
        
        if ~isempty(currentGroup)
            sixHourGroups{end+1} = currentGroup;
        end
        currentGroup = [];
        currentDate = dateshift(currentTime, 'start', 'day');
        currentHourGroup = hourGroup;
    end
    
    currentGroup{end+1} = gpmFiles{i};
end

% 添加最后一组
if ~isempty(currentGroup)
    sixHourGroups{end+1} = currentGroup;
end

fprintf('分组完成，共有 %d 个6小时时段\n', length(sixHourGroups));

% 预先读取第一个文件的经纬度信息
firstFilePath = fullfile(inputPath, gpmFiles{1});
lon = h5read(firstFilePath, '/Grid/lon');
lat = h5read(firstFilePath, '/Grid/lat');
fillValue = single(-9999.9);

fprintf('开始处理6小时累积降水数据...\n');

% 处理每个6小时时段
totalGroups = length(sixHourGroups);
completedGroups = 0;

for g = 1:totalGroups
    currentGroup = sixHourGroups{g};
    
    % 获取该时段的开始和结束时间
    firstFileName = currentGroup{1};
    lastFileName = currentGroup{end};
    
    % 从文件名中提取时间信息
    firstParts = strsplit(firstFileName, '.');
    firstDatePart = firstParts{5};
    firstTimeParts = strsplit(firstDatePart, '-');
    startDateStr = firstTimeParts{1};
    startTimeStr = firstTimeParts{2}(2:end);
    
    lastParts = strsplit(lastFileName, '.');
    lastDatePart = lastParts{5};
    lastTimeParts = strsplit(lastDatePart, '-');
    endTimeStr = lastTimeParts{3}(2:end);
    
    % 构建输出文件名
    outputFileName = sprintf('GPM_6hourly_%s%s_%s%s.nc', ...
                            startDateStr, startTimeStr, startDateStr, endTimeStr);
    outputFilePath = fullfile(outputPath, outputFileName);
    
    % 如果文件已存在，跳过
    if exist(outputFilePath, 'file')
        fprintf('文件已存在，跳过: %s\n', outputFileName);
        completedGroups = completedGroups + 1;
        continue;
    end
    
    % 检查是否有12个文件（完整的6小时）
    if length(currentGroup) ~= 12
        fprintf('警告: 第 %d 组只有 %d 个文件，不是完整的12个\n', g, length(currentGroup));
    end
    
    % 初始化6小时累积降水矩阵
    sixHourPrecip = zeros(size(lat, 1), size(lon, 1), 'single');
    
    % 处理该时段内的每个文件
    validFiles = 0;
    for f = 1:length(currentGroup)
        fileName = currentGroup{f};
        filePath = fullfile(inputPath, fileName);
        
        try
            % 读取降水数据
            precipData = h5read(filePath, '/Grid/precipitation');
            
            % 处理缺失值
            precipData(precipData == fillValue) = 0;
            
            % 将降水率(mm/hr)转换为降水量(mm/30min)
            halfHourPrecip = precipData * 0.5;
            
            % 累加降水量
            sixHourPrecip = sixHourPrecip + halfHourPrecip;
            validFiles = validFiles + 1;
            
        catch ME
            fprintf('  错误读取文件: %s\n', fileName);
            fprintf('  错误信息: %s\n', ME.message);
        end
    end
    
    % 如果所有文件都读取失败，跳过该时段
    if validFiles == 0
        fprintf('  所有文件读取失败，跳过该时段: %s\n', outputFileName);
        continue;
    end
    
    % 创建NetCDF文件
    nccreate(outputFilePath, 'precipitation', ...
             'Dimensions', {'lat', length(lat), 'lon', length(lon)}, ...
             'Datatype', 'single', ...
             'FillValue', fillValue);
    
    nccreate(outputFilePath, 'lon', ...
             'Dimensions', {'lon', length(lon)}, ...
             'Datatype', 'single');
    
    nccreate(outputFilePath, 'lat', ...
             'Dimensions', {'lat', length(lat)}, ...
             'Datatype', 'single');
    
    nccreate(outputFilePath, 'time', ...
             'Dimensions', {'time', 1}, ...
             'Datatype', 'double');
    
    % 写入数据
    ncwrite(outputFilePath, 'precipitation', sixHourPrecip);
    ncwrite(outputFilePath, 'lon', lon);
    ncwrite(outputFilePath, 'lat', lat);
    
    % 计算时间（使用6小时时段的开始时间）
    startYear = str2double(startDateStr(1:4));
    startMonth = str2double(startDateStr(5:6));
    startDay = str2double(startDateStr(7:8));
    startHour = str2double(startTimeStr(1:2));
    startMinute = str2double(startTimeStr(3:4));
    startSecond = str2double(startTimeStr(5:6));
    
    startDatetime = datetime(startYear, startMonth, startDay, ...
                            startHour, startMinute, startSecond);
    
    % 转换为秒 since 1980-01-06（与原始数据一致）
    baseDatetime = datetime(1980, 1, 6, 0, 0, 0);
    timeInSeconds = seconds(startDatetime - baseDatetime);
    ncwrite(outputFilePath, 'time', timeInSeconds);
    
    % 添加属性
    ncwriteatt(outputFilePath, 'precipitation', 'units', 'mm');
    ncwriteatt(outputFilePath, 'precipitation', 'long_name', '6-hour cumulative precipitation');
    ncwriteatt(outputFilePath, 'precipitation', 'missing_value', fillValue);
    
    ncwriteatt(outputFilePath, 'lon', 'units', 'degrees_east');
    ncwriteatt(outputFilePath, 'lon', 'long_name', 'Longitude');
    
    ncwriteatt(outputFilePath, 'lat', 'units', 'degrees_north');
    ncwriteatt(outputFilePath, 'lat', 'long_name', 'Latitude');
    
    ncwriteatt(outputFilePath, 'time', 'units', 'seconds since 1980-01-06 00:00:00 UTC');
    ncwriteatt(outputFilePath, 'time', 'long_name', 'Time');
    ncwriteatt(outputFilePath, 'time', 'calendar', 'julian');
    
    ncwriteatt(outputFilePath, '/', 'title', 'GPM 6-Hour Cumulative Precipitation');
    ncwriteatt(outputFilePath, '/', 'source', 'GPM IMERG Half-Hourly Data');
    ncwriteatt(outputFilePath, '/', 'time_coverage_start', ...
               datestr(startDatetime, 'yyyy-mm-ddTHH:MM:SSZ'));
    ncwriteatt(outputFilePath, '/', 'time_coverage_end', ...
               datestr(startDatetime + hours(5) + minutes(59) + seconds(59), 'yyyy-mm-ddTHH:MM:SSZ'));
    ncwriteatt(outputFilePath, '/', 'date_created', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    
    completedGroups = completedGroups + 1;
    
    % 每处理100组输出一次进度
    if mod(completedGroups, 100) == 0
        fprintf('已完成 %d/%d 组\n', completedGroups, totalGroups);
    end
end

fprintf('处理完成！共处理了 %d/%d 个6小时时段\n', completedGroups, totalGroups);