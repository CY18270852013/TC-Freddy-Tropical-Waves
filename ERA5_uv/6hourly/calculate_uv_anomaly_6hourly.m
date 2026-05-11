clear; clc;

%% 设置路径和参数
input_path = 'E:\Original_Data_of_Freddy\ERA5_dv_q_uv_200901_202312_every_6hours';
output_path = 'E:\Results_of_Freddy\u_v_anomaly_6hourly';
if ~exist(output_path, 'dir')
    mkdir(output_path);
end

output_file = fullfile(output_path, 'u_v_anomaly_6hourly_20220101_20231231.nc');

% 目标时间范围
target_start = datetime(2022, 1, 1, 0, 0, 0, 'TimeZone', 'UTC');
target_end = datetime(2023, 12, 31, 23, 59, 59, 'TimeZone', 'UTC');
climatology_start = datetime(2009, 1, 1, 0, 0, 0, 'TimeZone', 'UTC');
climatology_end = datetime(2023, 12, 31, 23, 59, 59, 'TimeZone', 'UTC');

% 创建所有文件的文件名列表（2009年1月到2023年12月）
file_list = cell(0, 1);
current_date = climatology_start;
while current_date <= climatology_end
    year_str = num2str(year(current_date));
    month_str = sprintf('%02d', month(current_date));
    filename = sprintf('%s%s_uv.nc', year_str, month_str);
    file_list{end+1} = fullfile(input_path, filename);
    current_date = current_date + calmonths(1);
end

% 使用第一个文件获取维度信息
first_file = file_list{1};
lon = ncread(first_file, 'longitude');
lat = ncread(first_file, 'latitude');
pres_levels = ncread(first_file, 'pressure_level');
time_var = ncread(first_file, 'valid_time');

% 获取850hPa的索引
target_pres = 850;
pres_idx = find(pres_levels == target_pres);

nLon = length(lon);      % 720
nLat = length(lat);      % 81
nPres = 1;               % 只处理850hPa
nTime_per_month = length(time_var);  % 每个月的时次数（约124）

%% 第一步：计算15年平均值和标准化变量
fprintf('步骤1: 计算15年平均值和标准化u、v变量 (850hPa)...\n');

% 初始化累积数组
u_sum = zeros(nLon, nLat, 'single');
v_sum = zeros(nLon, nLat, 'single');
time_count = zeros(nLon, nLat, 'single');

% 计算总时间步数
total_months = 15 * 12;  % 15年，每年12个月
nFiles = length(file_list);

% 第一次遍历：计算平均值
for i = 1:nFiles
    fprintf('处理文件中: %d/%d\n', i, nFiles);
    
    % 读取u和v数据（只读取850hPa层）
    u_data = ncread(file_list{i}, 'u', [1, 1, pres_idx, 1], [Inf, Inf, 1, Inf]);
    v_data = ncread(file_list{i}, 'v', [1, 1, pres_idx, 1], [Inf, Inf, 1, Inf]);
    
    % 处理缺失值
    u_missing_mask = isnan(u_data);
    v_missing_mask = isnan(v_data);
    
    % 将缺失值设为0以便累加
    u_data(u_missing_mask) = 0;
    v_data(v_missing_mask) = 0;
    
    % 累加
    u_sum = u_sum + sum(u_data, 4, 'omitnan');
    v_sum = v_sum + sum(v_data, 4, 'omitnan');
    
    % 更新有效计数
    valid_count = single(~u_missing_mask & ~v_missing_mask);
    time_count = time_count + sum(valid_count, 4);
    
    % 清除临时变量
    clear u_data v_data u_missing_mask v_missing_mask valid_count;
end

% 计算平均值
u_mean = zeros(nLon, nLat, 'single');
v_mean = zeros(nLon, nLat, 'single');
valid_mask = time_count > 0;
u_mean(valid_mask) = u_sum(valid_mask) ./ time_count(valid_mask);
v_mean(valid_mask) = v_sum(valid_mask) ./ time_count(valid_mask);
u_mean(~valid_mask) = NaN;
v_mean(~valid_mask) = NaN;

% 保存平均值供后续使用
mean_file = fullfile(output_path, 'uv_mean_850hPa.mat');
save(mean_file, 'u_mean', 'v_mean', 'lon', 'lat', 'pres_idx', '-v7.3');
fprintf('平均值计算完成并保存到: %s\n', mean_file);

% 清理不再需要的变量
clear u_sum v_sum time_count;

%% 第二步：计算标准化变量并构建气候态
fprintf('步骤2: 计算标准化变量并构建气候态...\n');

% 创建年积日映射（一年365天，每天4个时次）
nDoy = 365;
nHours_per_day = 4;
nTime_per_year = nDoy * nHours_per_day;  % 1460

% 初始化气候态累加数组
u_clim_sum = zeros(nLon, nLat, nTime_per_year, 'single');
v_clim_sum = zeros(nLon, nLat, nTime_per_year, 'single');
clim_count = zeros(nLon, nLat, nTime_per_year, 'single');

% 月天数（非闰年）
month_days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
cum_days = [0, cumsum(month_days(1:end-1))];

% 第二次遍历：计算标准化变量并累积气候态
for i = 1:nFiles
    fprintf('处理文件用于气候态: %d/%d\n', i, nFiles);
    
    % 读取数据
    u_data = ncread(file_list{i}, 'u', [1, 1, pres_idx, 1], [Inf, Inf, 1, Inf]);
    v_data = ncread(file_list{i}, 'v', [1, 1, pres_idx, 1], [Inf, Inf, 1, Inf]);
    
    % 计算标准化变量
    u_norm = u_data - u_mean;
    v_norm = v_data - v_mean;
    
    % 获取时间信息
    file_times = ncread(file_list{i}, 'valid_time');
    
    % 将时间转换为datetime（带时区）
    time_epoch = datetime(1970, 1, 1, 0, 0, 0, 'TimeZone', 'UTC');
    dt_times = time_epoch + seconds(double(file_times));
    
    % 获取文件日期（用于判断是否在目标年份）
    file_date = dt_times(1);
    
    % 对每个时间步进行处理
    for t = 1:length(dt_times)
        dt = dt_times(t);
        yr = year(dt);
        mo = month(dt);
        dy = day(dt);
        hr = hour(dt);
        
        % 跳过闰年的2月29日
        is_leap_year = (mod(yr, 4) == 0 && mod(yr, 100) ~= 0) || (mod(yr, 400) == 0);
        if is_leap_year && mo == 2 && dy == 29
            continue;
        end
        
        % 计算年积日（1-365）
        doy = cum_days(mo) + dy;
        
        % 确定时次索引（1-4）
        if hr == 0
            hour_idx = 1;
        elseif hr == 6
            hour_idx = 2;
        elseif hr == 12
            hour_idx = 3;
        elseif hr == 18
            hour_idx = 4;
        else
            continue;  % 跳过非6小时的时间
        end
        
        % 计算气候态索引
        clim_idx = (doy - 1) * nHours_per_day + hour_idx;
        
        % 累加到气候态
        u_clim_sum(:, :, clim_idx) = u_clim_sum(:, :, clim_idx) + u_norm(:, :, 1, t);
        v_clim_sum(:, :, clim_idx) = v_clim_sum(:, :, clim_idx) + v_norm(:, :, 1, t);
        clim_count(:, :, clim_idx) = clim_count(:, :, clim_idx) + 1;
    end
    
    clear u_data v_data u_norm v_norm file_times dt_times;
end

% 计算气候态平均值
u_climatology = zeros(nLon, nLat, nTime_per_year, 'single');
v_climatology = zeros(nLon, nLat, nTime_per_year, 'single');

for t = 1:nTime_per_year
    valid_mask = clim_count(:, :, t) > 0;
    u_climatology(:, :, t) = u_clim_sum(:, :, t) ./ clim_count(:, :, t);
    v_climatology(:, :, t) = v_clim_sum(:, :, t) ./ clim_count(:, :, t);
    u_climatology(~valid_mask, t) = NaN;
    v_climatology(~valid_mask, t) = NaN;
end

fprintf('气候态计算完成\n');

% 清理变量
clear u_clim_sum v_clim_sum clim_count;

%% 第三步：傅里叶滤波
fprintf('步骤3: 傅里叶滤波（保留前三阶谐波）...\n');

% 初始化拟合气候态数组
u_fit_climatology = zeros(size(u_climatology), 'single');
v_fit_climatology = zeros(size(v_climatology), 'single');

% 对每个格点进行傅里叶滤波
for i = 1:nLon
    for j = 1:nLat
        % 提取时间序列
        u_ts = squeeze(u_climatology(i, j, :));
        v_ts = squeeze(v_climatology(i, j, :));
        
        % 检查是否有有效数据
        if all(isnan(u_ts)) || all(isnan(v_ts))
            continue;
        end
        
        % 傅里叶变换
        u_fft = fft(u_ts);
        v_fft = fft(v_ts);
        
        % 保留前三阶谐波（直流分量 + 前三阶）
        % 注意：对于1460个点，前三阶对应索引2:4和end-2:end
        n = length(u_ts);
        u_fft(5:n-3) = 0;  % 保留前4个和后3个系数（对应直流和前3阶谐波）
        v_fft(5:n-3) = 0;
        
        % 逆傅里叶变换
        u_fit = real(ifft(u_fft));
        v_fit = real(ifft(v_fft));
        
        % 存储结果
        u_fit_climatology(i, j, :) = u_fit;
        v_fit_climatology(i, j, :) = v_fit;
    end
    
    if mod(i, 100) == 0
        fprintf('  已完成 %d/%d 个经度点\n', i, nLon);
    end
end

fprintf('傅里叶滤波完成\n');

% 保存气候态数据
climatology_file = fullfile(output_path, 'climatology_fit_850hPa.mat');
save(climatology_file, 'u_fit_climatology', 'v_fit_climatology', '-v7.3');

% 清理变量
clear u_climatology v_climatology;

%% 第四步：计算目标年份的异常值
fprintf('步骤4: 计算2022-2023年的异常值...\n');

% 确定目标年份的文件索引
target_files = cell(0, 1);
for i = 1:nFiles
    [~, filename] = fileparts(file_list{i});
    year_str = filename(1:4);
    file_year = str2double(year_str);
    
    if file_year >= 2022 && file_year <= 2023
        target_files{end+1} = file_list{i};
    end
end

nTargetFiles = length(target_files);

% 计算目标年份的总时间步数
total_target_steps = 0;
for i = 1:nTargetFiles
    file_times = ncread(target_files{i}, 'valid_time');
    total_target_steps = total_target_steps + length(file_times);
end

% 初始化异常值数组
u_anomaly = zeros(nLon, nLat, total_target_steps, 'single');
v_anomaly = zeros(nLon, nLat, total_target_steps, 'single');
time_values = zeros(total_target_steps, 1);

current_step = 1;

% 处理每个目标文件
for f = 1:nTargetFiles
    fprintf('处理目标文件: %d/%d\n', f, nTargetFiles);
    
    % 读取数据
    u_data = ncread(target_files{f}, 'u', [1, 1, pres_idx, 1], [Inf, Inf, 1, Inf]);
    v_data = ncread(target_files{f}, 'v', [1, 1, pres_idx, 1], [Inf, Inf, 1, Inf]);
    file_times = ncread(target_files{f}, 'valid_time');
    
    nSteps_in_file = size(u_data, 4);
    
    % 将时间转换为datetime（带时区）
    time_epoch = datetime(1970, 1, 1, 0, 0, 0, 'TimeZone', 'UTC');
    dt_times = time_epoch + seconds(double(file_times));
    
    % 对每个时间步进行处理
    for t = 1:nSteps_in_file
        dt = dt_times(t);
        yr = year(dt);
        mo = month(dt);
        dy = day(dt);
        hr = hour(dt);
        
        % 计算标准化变量
        u_norm = u_data(:, :, 1, t) - u_mean;
        v_norm = v_data(:, :, 1, t) - v_mean;
        
        % 跳过闰年的2月29日
        is_leap_year = (mod(yr, 4) == 0 && mod(yr, 100) ~= 0) || (mod(yr, 400) == 0);
        if is_leap_year && mo == 2 && dy == 29
            continue;
        end
        
        % 计算年积日（1-365）
        doy = cum_days(mo) + dy;
        
        % 确定时次索引（1-4）
        if hr == 0
            hour_idx = 1;
        elseif hr == 6
            hour_idx = 2;
        elseif hr == 12
            hour_idx = 3;
        elseif hr == 18
            hour_idx = 4;
        else
            continue;  % 跳过非6小时的时间
        end
        
        % 计算气候态索引
        clim_idx = (doy - 1) * nHours_per_day + hour_idx;
        
        % 获取拟合气候态
        u_clim = u_fit_climatology(:, :, clim_idx);
        v_clim = v_fit_climatology(:, :, clim_idx);
        
        % 计算异常值
        u_anom = u_norm - u_clim;
        v_anom = v_norm - v_clim;
        
        % 处理缺失值
        u_anom(isnan(u_anom)) = -9999.9;
        v_anom(isnan(v_anom)) = -9999.9;
        
        % 存储结果
        u_anomaly(:, :, current_step) = u_anom;
        v_anomaly(:, :, current_step) = v_anom;
        time_values(current_step) = double(file_times(t));
        
        current_step = current_step + 1;
    end
    
    clear u_data v_data file_times dt_times;
end

% 调整数组大小以防有跳过的时间步
u_anomaly = u_anomaly(:, :, 1:current_step-1);
v_anomaly = v_anomaly(:, :, 1:current_step-1);
time_values = time_values(1:current_step-1);

fprintf('异常值计算完成，共 %d 个时间步\n', current_step-1);

%% 第五步：保存为NetCDF文件
fprintf('步骤5: 保存为NetCDF文件...\n');

% 删除已存在的文件（如果存在）
if exist(output_file, 'file')
    delete(output_file);
end

% 获取时间维度大小
nTime_final = size(u_anomaly, 3);

% 创建NetCDF文件
nccreate(output_file, 'u_anomaly', ...
    'Dimensions', {'longitude', nLon, 'latitude', nLat, 'time', nTime_final}, ...
    'Datatype', 'single', ...
    'FillValue', single(-9999.9));

nccreate(output_file, 'v_anomaly', ...
    'Dimensions', {'longitude', nLon, 'latitude', nLat, 'time', nTime_final}, ...
    'Datatype', 'single', ...
    'FillValue', single(-9999.9));

nccreate(output_file, 'longitude', ...
    'Dimensions', {'longitude', nLon}, ...
    'Datatype', 'double');

nccreate(output_file, 'latitude', ...
    'Dimensions', {'latitude', nLat}, ...
    'Datatype', 'double');

nccreate(output_file, 'time', ...
    'Dimensions', {'time', nTime_final}, ...
    'Datatype', 'double');

% 写入数据
ncwrite(output_file, 'u_anomaly', u_anomaly);
ncwrite(output_file, 'v_anomaly', v_anomaly);
ncwrite(output_file, 'longitude', lon);
ncwrite(output_file, 'latitude', lat);
ncwrite(output_file, 'time', time_values);

% 添加属性
ncwriteatt(output_file, 'u_anomaly', 'long_name', 'U component wind anomaly');
ncwriteatt(output_file, 'u_anomaly', 'units', 'm s**-1');
ncwriteatt(output_file, 'u_anomaly', 'standard_name', 'eastward_wind_anomaly');
ncwriteatt(output_file, 'u_anomaly', 'level', '850 hPa');

ncwriteatt(output_file, 'v_anomaly', 'long_name', 'V component wind anomaly');
ncwriteatt(output_file, 'v_anomaly', 'units', 'm s**-1');
ncwriteatt(output_file, 'v_anomaly', 'standard_name', 'northward_wind_anomaly');
ncwriteatt(output_file, 'v_anomaly', 'level', '850 hPa');

ncwriteatt(output_file, 'longitude', 'long_name', 'longitude');
ncwriteatt(output_file, 'longitude', 'units', 'degrees_east');
ncwriteatt(output_file, 'longitude', 'standard_name', 'longitude');

ncwriteatt(output_file, 'latitude', 'long_name', 'latitude');
ncwriteatt(output_file, 'latitude', 'units', 'degrees_north');
ncwriteatt(output_file, 'latitude', 'standard_name', 'latitude');

ncwriteatt(output_file, 'time', 'long_name', 'time');
ncwriteatt(output_file, 'time', 'units', 'seconds since 1970-01-01 00:00:00');
ncwriteatt(output_file, 'time', 'calendar', 'proleptic_gregorian');

% 全局属性
ncwriteatt(output_file, '/', 'title', 'ERA5 U and V Wind Anomaly at 850 hPa');
ncwriteatt(output_file, '/', 'source', 'ERA5 reanalysis');
ncwriteatt(output_file, '/', 'institution', 'European Centre for Medium-Range Weather Forecasts');
ncwriteatt(output_file, '/', 'history', sprintf('Created by MATLAB on %s', datestr(now)));
ncwriteatt(output_file, '/', 'climatology_period', '2009-01-01 to 2023-12-31');
ncwriteatt(output_file, '/', 'target_period', '2022-01-01 to 2023-12-31');
ncwriteatt(output_file, '/', 'time_resolution', '6-hourly');
ncwriteatt(output_file, '/', 'spatial_resolution', '0.5 degree x 0.5 degree');
ncwriteatt(output_file, '/', 'latitude_range', '10N to 30S');
ncwriteatt(output_file, '/', 'longitude_range', '0 to 359.5E');
ncwriteatt(output_file, '/', 'method', '15-year mean removed + FFT filtering (first 3 harmonics)');
ncwriteatt(output_file, '/', 'missing_value', -9999.9);
ncwriteatt(output_file, '/', 'purpose', 'For studying tropical cyclone Freddy (2023) in South Indian Ocean');

fprintf('文件保存完成: %s\n', output_file);
fprintf('处理完成！\n');

%% 清理工作区
clear u_anomaly v_anomaly time_values;
clear u_mean v_mean u_fit_climatology v_fit_climatology;
fprintf('所有步骤完成！\n');