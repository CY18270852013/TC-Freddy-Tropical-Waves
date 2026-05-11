clear; clc;

%% 设置路径和参数
input_path = 'E:\Original_Data_of_Freddy\ERA5_dv_q_uv_200901_202312_every_6hours';
output_path = 'E:\Results_of_Freddy\divergence_anomaly_6hourly';

% 创建输出目录
if ~exist(output_path, 'dir')
    mkdir(output_path);
end

% 目标时间段
target_start = datetime(2022, 1, 1);
target_end = datetime(2023, 12, 31);

% 参考时间段（15年）
ref_start = datetime(2009, 1, 1);
ref_end = datetime(2023, 12, 31);

% 气压层（只取850hPa）
target_pressure = 850;

fprintf('开始处理ERA5散度数据...\n');
fprintf('参考期: %s 到 %s\n', datestr(ref_start), datestr(ref_end));
fprintf('目标期: %s 到 %s\n', datestr(target_start), datestr(target_end));

%% 步骤1: 获取文件列表并筛选
% 列出所有dv文件
all_files = dir(fullfile(input_path, '*_dv.nc'));
n_files = length(all_files);

% 筛选2009-2023年的文件
selected_files = {};
selected_dates = [];

for i = 1:n_files
    filename = all_files(i).name;
    % 提取年月信息
    year_str = filename(1:4);
    month_str = filename(5:6);
    
    try
        file_date = datetime(str2double(year_str), str2double(month_str), 1);
        
        if file_date >= ref_start && file_date <= ref_end
            selected_files{end+1} = fullfile(input_path, filename);
            selected_dates = [selected_dates; file_date];
        end
    catch
        continue;
    end
end

% 按日期排序
[~, sort_idx] = sort(selected_dates);
selected_files = selected_files(sort_idx);
n_selected = length(selected_files);

fprintf('找到 %d 个月份的数据文件\n', n_selected);

%% 步骤2: 读取维度信息（从第一个文件）
fprintf('读取维度信息...\n');
first_file = selected_files{1};

% 读取维度
lon = ncread(first_file, 'longitude');
lat = ncread(first_file, 'latitude');
pres_levels = ncread(first_file, 'pressure_level');

% 找到850hPa的索引
pres_idx = find(pres_levels == target_pressure, 1);
if isempty(pres_idx)
    error('未找到850hPa气压层！');
end

% 维度信息
nLon = length(lon);
nLat = length(lat);

fprintf('空间维度: 经度 %d, 纬度 %d\n', nLon, nLat);
fprintf('气压层: %d hPa\n', target_pressure);

%% 步骤3: 计算15年平均值（只处理850hPa）
fprintf('步骤1: 计算15年平均值 (2009-2023)...\n');

% 初始化累加数组
sum_d = zeros(nLon, nLat, 'double');
count_d = zeros(nLon, nLat, 'double');

% 逐月读取并累加
for f = 1:n_selected
    fprintf('  处理文件 %d/%d: %s\n', f, n_selected, selected_files{f});
    
    % 读取当前月份的850hPa散度数据
    d_data = ncread(selected_files{f}, 'd', [1, 1, pres_idx, 1], [nLon, nLat, 1, Inf]);
    
    % 将数据重塑为3D数组（经度×纬度×时间）
    d_data = squeeze(d_data);
    
    % 累加
    valid_mask = ~isnan(d_data);
    d_data(isnan(d_data)) = 0;
    
    % 对时间维度求和
    sum_d = sum_d + sum(d_data, 3);
    count_d = count_d + sum(valid_mask, 3);
    
    % 释放内存
    clear d_data valid_mask;
end

% 计算15年平均
divergence_15years_mean = sum_d ./ count_d;
divergence_15years_mean(count_d == 0) = NaN;

fprintf('15年平均计算完成\n');

%% 步骤4: 标准化处理并计算气候态
fprintf('步骤2-3: 标准化处理并计算气候态...\n');

% 初始化气候态数组（1460个时次：365天×4）
climatology = zeros(nLon, nLat, 1460, 'single');
climatology_count = zeros(nLon, nLat, 1460, 'single');

% 计算每个时次在年内的位置（1-1460）
% 定义每月的天数（不考虑闰年）
month_days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
cum_days = cumsum([0, month_days]) * 4;  % 转换为6小时时次

% 逐月处理
for f = 1:n_selected
    fprintf('  处理气候态文件 %d/%d...\n', f, n_selected);
    
    % 读取当前月份的850hPa散度数据
    d_data = ncread(selected_files{f}, 'd', [1, 1, pres_idx, 1], [nLon, nLat, 1, Inf]);
    d_data = squeeze(d_data);
    
    % 读取时间信息
    time_data = ncread(selected_files{f}, 'valid_time');
    
    % 标准化：减去15年平均
    divergence_normalized = d_data - divergence_15years_mean; % 隐式扩展（Implicit Expansion）
    
    % 计算每个时次对应的年积日和时次索引
    for t = 1:length(time_data)
        % 将秒转换为datetime
        dt = datetime(time_data(t), 'ConvertFrom', 'epochtime', 'Epoch', '1970-01-01');
        
        % 获取月和日
        month_val = month(dt);
        day_val = day(dt);
        hour_val = hour(dt);
        
        % 计算年积日（1-365）
        day_of_year = cum_days(month_val)/4 + day_val;
        
        % 计算6小时时次索引（1-4）
        time_of_day = floor(hour_val/6) + 1;
        
        % 计算气候态数组中的索引（1-1460）
        clim_idx = (day_of_year - 1) * 4 + time_of_day;
        
        % 跳过闰年的2月29日（在1460个时次中不存在）
        if month_val == 2 && day_val == 29
            continue;
        end
        
        % 累加到气候态
        current_data = divergence_normalized(:, :, t);
        valid_mask = ~isnan(current_data);
        current_data(isnan(current_data)) = 0;
        
        climatology(:, :, clim_idx) = climatology(:, :, clim_idx) + current_data;
        climatology_count(:, :, clim_idx) = climatology_count(:, :, clim_idx) + valid_mask;
    end
    
    % 释放内存
    clear d_data divergence_normalized time_data;
end

% 计算气候态平均值
valid_mask_count = climatology_count > 0;
climatology(valid_mask_count) = climatology(valid_mask_count) ./ climatology_count(valid_mask_count);
climatology(~valid_mask_count) = NaN;

fprintf('气候态计算完成，维度: %dx%dx%d\n', size(climatology, 1), size(climatology, 2), size(climatology, 3));

%% 步骤5: 傅里叶滤波（保留前三阶谐波）
fprintf('步骤4-5: 傅里叶滤波（保留前三阶谐波）...\n');

[nLon, nLat, nClimTime] = size(climatology);
fit_climatology = zeros(size(climatology), 'single');

% 对每个格点进行傅里叶滤波
for i = 1:nLon
    for j = 1:nLat
        % 提取时间序列
        time_series = squeeze(climatology(i, j, :));
        
        % 检查是否有有效数据
        if all(isnan(time_series))
            fit_climatology(i, j, :) = NaN;
            continue;
        end
        
        % 用线性插值填充NaN值
        nan_mask = isnan(time_series);
        if any(nan_mask)
            valid_indices = find(~nan_mask);
            time_series(nan_mask) = interp1(valid_indices, time_series(valid_indices), find(nan_mask), 'linear');
        end
        
        % 傅里叶变换
        fft_series = fft(time_series);
        n = length(fft_series);
        
        % 保留前三阶谐波
        fft_filtered = zeros(size(fft_series));
        
        % 保留直流分量（索引1）
        fft_filtered(1) = fft_series(1);
        
        % 保留前三阶谐波的正频率部分（索引2-4）
        fft_filtered(2:4) = fft_series(2:4);
        
        % 保留前三阶谐波的负频率部分（索引n-2:end）
        fft_filtered(n-2:end) = fft_series(n-2:end);
        
        % 逆傅里叶变换
        fit_series = real(ifft(fft_filtered));
        fit_climatology(i, j, :) = fit_series;
    end
    
    if mod(i, 100) == 0
        fprintf('  已处理 %d/%d 个经度点...\n', i, nLon);
    end
end

fprintf('傅里叶滤波完成\n');

%% 步骤6: 计算2022-2023年的异常值
fprintf('步骤6: 计算2022-2023年的异常值...\n');

% 筛选2022-2023年的文件
target_files = {};
for f = 1:n_selected
    file_date = selected_dates(f);
    if file_date >= datetime(2022, 1, 1) && file_date <= datetime(2023, 12, 31)
        target_files{end+1} = selected_files{f};
    end
end

n_target_files = length(target_files);

% 预分配异常值数组（2920个时次）
n_target_times = 2920;  % 730天 × 4时次/天
divergence_anomaly = zeros(nLon, nLat, n_target_times, 'single');
time_values = zeros(n_target_times, 1);

time_counter = 1;

% 处理每个目标文件
for f = 1:n_target_files
    fprintf('  处理目标文件 %d/%d: %s\n', f, n_target_files, target_files{f});
    
    % 读取当前月份的850hPa散度数据
    d_data = ncread(target_files{f}, 'd', [1, 1, pres_idx, 1], [nLon, nLat, 1, Inf]);
    d_data = squeeze(d_data);
    
    % 读取时间信息
    time_data = ncread(target_files{f}, 'valid_time');
    n_times = length(time_data);
    
    % 标准化：减去15年平均
    divergence_normalized = d_data - divergence_15years_mean;
    
    % 对每个时次计算异常值
    for t = 1:n_times
        % 将秒转换为datetime
        dt = datetime(time_data(t), 'ConvertFrom', 'epochtime', 'Epoch', '1970-01-01');
        
        % 保存时间值
        time_values(time_counter) = datenum(dt);
        
        % 获取月和日
        month_val = month(dt);
        day_val = day(dt);
        hour_val = hour(dt);
        
        % 计算年积日（1-365）
        day_of_year = cum_days(month_val)/4 + day_val;
        
        % 计算6小时时次索引（1-4）
        time_of_day = floor(hour_val/6) + 1;
        
        % 计算气候态数组中的索引（1-1460）
        clim_idx = (day_of_year - 1) * 4 + time_of_day;
        
        % 跳过闰年的2月29日（在1460个时次中不存在）
        if month_val == 2 && day_val == 29
            continue;
        end
        
        % 提取对应的气候态值
        clim_value = fit_climatology(:, :, clim_idx);
        
        % 计算异常值
        current_normalized = divergence_normalized(:, :, t);
        anomaly = current_normalized - clim_value;
        
        % 处理NaN值
        anomaly(isnan(anomaly) | isnan(current_normalized)) = NaN;
        
        % 保存异常值
        divergence_anomaly(:, :, time_counter) = anomaly;
        
        time_counter = time_counter + 1;
    end
    
    % 释放内存
    clear d_data divergence_normalized time_data;
end

% 验证时次数
expected_times = 2920;
actual_times = time_counter - 1;

if actual_times ~= expected_times
    fprintf('警告: 实际时次数 %d 不等于预期时次数 %d\n', actual_times, expected_times);
    
    % 如果有缺失，用NaN填充
    if actual_times < expected_times
        divergence_anomaly(:, :, actual_times+1:expected_times) = NaN;
        time_values(actual_times+1:expected_times) = NaN;
        fprintf('  已用NaN填充缺失的时次\n');
    else
        % 如果多于预期，截断
        divergence_anomaly = divergence_anomaly(:, :, 1:expected_times);
        time_values = time_values(1:expected_times);
        fprintf('  已截断多余的时次\n');
    end
else
    fprintf('时次数验证通过: %d 个时次\n', actual_times);
end

%% 步骤7: 保存为NetCDF文件
fprintf('步骤7: 保存为NetCDF文件...\n');

output_file = fullfile(output_path, 'divergence_anomaly_6hourly_20220101_20231231.nc');

% 删除已存在的文件
if exist(output_file, 'file')
    delete(output_file);
end

n_time = size(divergence_anomaly, 3);

% 创建NetCDF文件
nccreate(output_file, 'divergence_anomaly', ...
    'Dimensions', {'longitude', nLon, 'latitude', nLat, 'time', n_time}, ...
    'Datatype', 'single', ...
    'FillValue', NaN);

nccreate(output_file, 'longitude', 'Dimensions', {'longitude', nLon}, 'Datatype', 'double');
nccreate(output_file, 'latitude', 'Dimensions', {'latitude', nLat}, 'Datatype', 'double');
nccreate(output_file, 'time', 'Dimensions', {'time', n_time}, 'Datatype', 'double');

% 写入变量
ncwrite(output_file, 'divergence_anomaly', divergence_anomaly);
ncwrite(output_file, 'longitude', lon);
ncwrite(output_file, 'latitude', lat);
ncwrite(output_file, 'time', time_values);

% 添加变量属性
ncwriteatt(output_file, 'divergence_anomaly', 'long_name', 'Divergence Anomaly');
ncwriteatt(output_file, 'divergence_anomaly', 'units', 's^-1');
ncwriteatt(output_file, 'divergence_anomaly', 'standard_name', 'divergence_of_wind_anomaly');
ncwriteatt(output_file, 'divergence_anomaly', 'pressure_level', '850 hPa');
ncwriteatt(output_file, 'divergence_anomaly', 'description', 'Divergence anomaly calculated by removing 15-year mean and FFT-filtered climatology');

ncwriteatt(output_file, 'longitude', 'long_name', 'Longitude');
ncwriteatt(output_file, 'longitude', 'units', 'degrees_east');
ncwriteatt(output_file, 'longitude', 'standard_name', 'longitude');

ncwriteatt(output_file, 'latitude', 'long_name', 'Latitude');
ncwriteatt(output_file, 'latitude', 'units', 'degrees_north');
ncwriteatt(output_file, 'latitude', 'standard_name', 'latitude');

ncwriteatt(output_file, 'time', 'long_name', 'Time');
ncwriteatt(output_file, 'time', 'units', 'days since 0000-01-01 00:00:00');
ncwriteatt(output_file, 'time', 'calendar', 'proleptic_gregorian');
ncwriteatt(output_file, 'time', 'standard_name', 'time');

% 添加全局属性
ncwriteatt(output_file, '/', 'title', 'ERA5 Divergence Anomaly at 850 hPa');
ncwriteatt(output_file, '/', 'source', 'ERA5 reanalysis');
ncwriteatt(output_file, '/', 'institution', 'European Centre for Medium-Range Weather Forecasts');
ncwriteatt(output_file, '/', 'history', sprintf('Created by MATLAB on %s', datestr(now)));
ncwriteatt(output_file, '/', 'reference_period', '2009-2023');
ncwriteatt(output_file, '/', 'target_period', '2022-01-01 to 2023-12-31');
ncwriteatt(output_file, '/', 'time_resolution', '6-hourly');
ncwriteatt(output_file, '/', 'spatial_resolution', '0.5 degree x 0.5 degree');
ncwriteatt(output_file, '/', 'latitude_range', '10N to 30S');
ncwriteatt(output_file, '/', 'longitude_range', '0 to 359.5E');
ncwriteatt(output_file, '/', 'method', '15-year mean removed + FFT filtering (first 3 harmonics)');
ncwriteatt(output_file, '/', 'author', 'Freddy ChenYong');
ncwriteatt(output_file, '/', 'purpose', 'Study environmental characteristics and life cycle mechanisms of Tropical Cyclone Freddy in the South Indian Ocean');

fprintf('NetCDF文件保存完成: %s\n', output_file);
fprintf('处理完成！\n');

%% 显示结果信息
fprintf('\n========== 处理结果摘要 ==========\n');
fprintf('输出文件: %s\n', output_file);
fprintf('变量名: divergence_anomaly\n');
fprintf('维度: 经度 %d, 纬度 %d, 时间 %d\n', nLon, nLat, n_time);
fprintf('时间范围: %s 到 %s\n', datestr(min(time_values(~isnan(time_values)))), datestr(max(time_values(~isnan(time_values)))));
fprintf('气压层: 850 hPa\n');
fprintf('空间范围: %.1f°N ~ %.1f°N, %.1f°E ~ %.1f°E\n', max(lat), min(lat), min(lon), max(lon));
fprintf('=================================\n');