clear; clc;

%% 参数设置
input_path = 'E:\Original_Data_of_Freddy\OLR_daily_19800101_20231231';
output_path = 'E:\Results_of_Freddy\olr_daily';

% 创建输出目录
if ~exist(output_path, 'dir')
    mkdir(output_path);
end

%% 步骤1: 读取并处理2009-2023年所有OLR数据，计算15年平均值
fprintf('步骤1: 计算15年平均值和标准化OLR\n');

% 获取所有2009-2023年的OLR文件
all_files = dir(fullfile(input_path, 'olr-daily_v01r02_*.nc'));
selected_files = {};
selected_years = [];

for i = 1:length(all_files)
    filename = all_files(i).name;
    % 从文件名中提取年份
    if contains(filename, 'olr-daily_v01r02_')
        year_str = filename(18:21);  % 例如: 2009
        year_num = str2double(year_str);
        if year_num >= 2009 && year_num <= 2023
            selected_files{end+1} = fullfile(input_path, filename);
            selected_years(end+1) = year_num;
        end
    end
end

% 按年份排序
[selected_years, sort_idx] = sort(selected_years);
selected_files = selected_files(sort_idx);

n_years = length(selected_files);
fprintf('找到 %d 个符合年份范围的文件 (2009-2023)\n', n_years);

% 读取第一个文件获取维度信息
first_file = selected_files{1};
lon = ncread(first_file, 'lon');
lat = ncread(first_file, 'lat');
time_info = ncread(first_file, 'time');

nLon = length(lon);  % 360
nLat = length(lat);  % 180

% 为了减少内存使用，我们将分年处理并累加
% 首先计算每个位置15年的平均值
total_olr = zeros(nLat, nLon, 'single');
valid_count = zeros(nLat, nLon, 'single');

% 同时存储每年数据以便后续处理（按需）
olr_data_cell = cell(n_years, 1);
all_dates = [];

for y = 1:n_years
    fprintf('  处理第 %d/%d 年 (年份: %d)...\n', y, n_years, selected_years(y));
    
    % 读取当前年份的OLR数据
    olr_current = ncread(selected_files{y}, 'olr');  % 维度: lon x lat x time
    % 转换为 lat x lon x time 以便处理
    olr_current = permute(olr_current, [2, 1, 3]);  % 现在维度: lat x lon x time
    
    n_days = size(olr_current, 3);
    
    % 创建该年份的日期序列
    start_date = datetime(selected_years(y), 1, 1);
    year_dates = start_date + days(0:n_days-1)';
    
    % 如果是闰年且天数超过365，则去除2月29日
    if n_days > 365
        % 找到2月29日的索引
        feb29_idx = month(year_dates) == 2 & day(year_dates) == 29;
        if any(feb29_idx)
            olr_current = olr_current(:, :, ~feb29_idx);
            year_dates = year_dates(~feb29_idx);
            fprintf('     去除闰年2月29日数据\n');
        end
    end
    
    % 确保每年有365天
    if size(olr_current, 3) ~= 365
        fprintf('     警告: 年份 %d 有 %d 天数据\n', selected_years(y), size(olr_current, 3));
        % 如果天数不是365，我们可能需要调整，但通常应该是365天
    end
    
    % 存储数据
    olr_data_cell{y} = olr_current;
    all_dates = [all_dates; year_dates]; % 5475*1
    
    % 处理缺失值并累加计算平均值
    % OLR数据的缺失值标记为0（根据数据描述）
    valid_mask = (olr_current ~= 0);
    
    % 将缺失值设为0以便累加
    olr_for_sum = olr_current;
    olr_for_sum(~valid_mask) = 0;
    
    % 累加总OLR值 - 使用 double 计算，然后转换回 single
    total_olr = total_olr + single(sum(olr_for_sum, 3, 'double'));
    
    % 累加有效计数 - 修改这里：直接使用 sum，然后转换
    valid_count = valid_count + single(sum(valid_mask, 3, 'double'));
end

% 计算15年平均值
mean_olr = zeros(nLat, nLon, 'single');
non_zero_mask = (valid_count > 0);
mean_olr(non_zero_mask) = total_olr(non_zero_mask) ./ valid_count(non_zero_mask);
mean_olr(~non_zero_mask) = 0;  % 使用0作为缺失值

fprintf('步骤1完成: 15年平均OLR计算完成\n');

% 保存中间结果
save('mean_olr_15year.mat', 'mean_olr', 'lon', 'lat', 'valid_count', '-v7.3');

% 清理内存
clear olr_for_sum valid_mask total_olr;

%% 步骤2: 计算标准化OLR异常（相对于15年平均）
fprintf('步骤2: 计算标准化OLR异常\n');

% 合并所有年份数据到一个三维数组
n_total_days = length(all_dates);
olr_all_years = zeros(nLat, nLon, n_total_days, 'single');

start_idx = 1;
for y = 1:n_years
    olr_current = olr_data_cell{y};
    n_days_current = size(olr_current, 3);
    end_idx = start_idx + n_days_current - 1;
    
    olr_all_years(:, :, start_idx:end_idx) = olr_current;
    start_idx = end_idx + 1;
end

% 计算标准化OLR（减去气候平均值）
normalized_olr = zeros(size(olr_all_years), 'single');
for d = 1:n_total_days
    normalized_olr(:, :, d) = olr_all_years(:, :, d) - mean_olr;
    
    % 处理缺失值：如果原始数据是缺失值，则标准化值也设为缺失值
    missing_mask = (olr_all_years(:, :, d) == 0);
    normalized_olr(:, :, d) = normalized_olr(:, :, d) .* ~missing_mask;
    
    if mod(d, 500) == 0
        fprintf('  已处理 %d/%d 天数据...\n', d, n_total_days);
    end
end

fprintf('步骤2完成: 标准化OLR异常计算完成\n');

% 保存中间结果
save('normalized_olr_2009_2023.mat', 'normalized_olr', 'all_dates', 'lon', 'lat', '-v7.3');

% 清理内存
clear olr_data_cell olr_all_years;

%% 步骤3: 计算气候态并进行傅里叶滤波
fprintf('步骤3: 计算气候态并进行傅里叶滤波...\n');

% 创建气候态（365天）
climatology = zeros(nLat, nLon, 365, 'single');
count = zeros(nLat, nLon, 365, 'single');

% 用于计算年积日的累积天数（非闰年）
cum_days = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];

% 将每天的数据累加到对应年积日
for d = 1:n_total_days
    current_date = all_dates(d);
    year_val = year(current_date);
    month_val = month(current_date);
    day_val = day(current_date);
    
    % 计算年积日（1-365）
    doy = cum_days(month_val) + day_val;
    
    % 获取当前天的标准化OLR数据
    current_olr = normalized_olr(:, :, d);
    
    % 处理缺失值（缺失值=0）
    valid_mask = (current_olr ~= 0);
    
    % 累加到对应年积日
    for lat_idx = 1:nLat
        for lon_idx = 1:nLon
            if valid_mask(lat_idx, lon_idx)
                climatology(lat_idx, lon_idx, doy) = climatology(lat_idx, lon_idx, doy) + current_olr(lat_idx, lon_idx);
                count(lat_idx, lon_idx, doy) = count(lat_idx, lon_idx, doy) + 1;
            end
        end
    end
    
    if mod(d, 500) == 0
        fprintf('  已处理 %d/%d 天数据计算气候态...\n', d, n_total_days);
    end
end

% 计算气候态平均值
valid_count_mask = (count > 0);
climatology(valid_count_mask) = climatology(valid_count_mask) ./ count(valid_count_mask);
climatology(~valid_count_mask) = 0;  % 缺失值设为0

fprintf('气候态计算完成，维度: %dx%dx%d\n', size(climatology, 1), size(climatology, 2), size(climatology, 3));

% 保存中间结果
save(fullfile(output_path, 'climatology_365day.mat'), 'climatology', 'lon', 'lat', '-v7.3');

% 清理内存
clear count valid_count_mask current_olr;

%% 步骤4: 傅里叶滤波（保留前三阶谐波）
fprintf('步骤4: 傅里叶滤波...\n');

[nLat, nLon, nDays] = size(climatology);  % 180 x 360 x 365
fit_climatology = zeros(size(climatology), 'single');

for lat_idx = 1:nLat
    for lon_idx = 1:nLon
        time_series = squeeze(climatology(lat_idx, lon_idx, :));
        
        % 如果所有值都是缺失值，跳过
        if all(time_series == 0)
            fit_climatology(lat_idx, lon_idx, :) = 0;
            continue;
        end
        
        % 傅里叶变换
        fft_series = fft(time_series);
        n = length(fft_series);
        
        % 保留直流分量和前三个谐波（共7个系数）
        % 保留: 索引1（直流）, 2-4（前三个正频率）, 和 n-2:n（对应的负频率）
        fft_filtered = zeros(size(fft_series));
        fft_filtered(1) = fft_series(1);  % 直流分量
        fft_filtered(2:4) = fft_series(2:4);  % 前三个正频率
        fft_filtered(end-1:end) = fft_series(end-1:end);  % 最后两个（对于365点FFT）
        if n > 6
            fft_filtered(n-2) = fft_series(n-2);  % 第三个负频率（如果存在）
        end
        
        % 逆傅里叶变换
        fit_series = real(ifft(fft_filtered));
        fit_climatology(lat_idx, lon_idx, :) = fit_series;
    end
    
    if mod(lat_idx, 30) == 0
        fprintf('  已处理 %d/%d 个纬度...\n', lat_idx, nLat);
    end
end

fprintf('傅里叶滤波完成\n');

% 保存中间结果
save(fullfile(output_path, 'fit_climatology_365day.mat'), 'fit_climatology', 'lon', 'lat', '-v7.3');

% 清理内存
clear climatology fft_series fft_filtered time_series;

%% 步骤5: 计算2022-2023年最终异常值
fprintf('步骤5: 计算2022-2023年最终异常值...\n');

% 提取2022-2023年的数据
target_start_date = datetime(2022, 1, 1);
target_end_date = datetime(2023, 12, 31);

% 找到2022-2023年在所有日期中的索引
target_indices = find(all_dates >= target_start_date & all_dates <= target_end_date);
target_dates = all_dates(target_indices);
target_normalized_olr = normalized_olr(:, :, target_indices);

nTime = length(target_dates);
fprintf('目标时间范围: %s 到 %s，共 %d 天\n', ...
    datestr(target_start_date), datestr(target_end_date), nTime);

% 计算最终异常值
olr_anomaly = zeros(nLat, nLon, nTime, 'single');

for t = 1:nTime
    current_date = target_dates(t);
    month_val = month(current_date);
    day_val = day(current_date);
    
    % 计算年积日
    doy = cum_days(month_val) + day_val;
    
    % 获取当前天的标准化OLR
    current_normalized = target_normalized_olr(:, :, t);
    
    % 获取滤波后的气候态值
    climate_value = fit_climatology(:, :, doy);
    
    % 计算异常值（标准化OLR减去滤波后的气候态）
    anomaly = current_normalized - climate_value;
    
    % 处理缺失值
    missing_mask = (current_normalized == 0);
    anomaly(missing_mask) = 0;
    
    olr_anomaly(:, :, t) = anomaly;
    
    if mod(t, 100) == 0
        fprintf('  已处理 %d/%d 天...\n', t, nTime);
    end
end

fprintf('步骤5完成: 2022-2023年OLR异常值计算完成\n');

% 保存中间结果
save(fullfile(output_path, 'olr_anomaly_2022_2023_raw.mat'), ...
    'olr_anomaly', 'lon', 'lat', 'target_dates', '-v7.3');

% 清理内存
clear target_normalized_olr normalized_olr fit_climatology;

%% 步骤6: 保存为NetCDF文件
fprintf('步骤6: 保存为NetCDF文件...\n');

% 创建输出文件名
output_file = fullfile(output_path, 'olr_anomaly_daily_20220101_20231231.nc');

% 删除已存在的文件（如果存在）
if exist(output_file, 'file')
    delete(output_file);
end

% 创建时间变量（从1970-01-01开始的天数，与原始数据一致）
time_days_since_1970 = days(target_dates - datetime(1970, 1, 1));

% 创建NetCDF文件 - 注意维度顺序与数据维度匹配
% 数据维度是 [lat, lon, time]，所以应该按这个顺序定义维度
nccreate(output_file, 'olr_anomaly_daily', ...
    'Dimensions', {'lat', nLat, 'lon', nLon, 'time', nTime}, ...
    'Datatype', 'single', ...
    'FillValue', single(0));

nccreate(output_file, 'lon', 'Dimensions', {'lon', nLon}, 'Datatype', 'single');
nccreate(output_file, 'lat', 'Dimensions', {'lat', nLat}, 'Datatype', 'single');
nccreate(output_file, 'time', 'Dimensions', {'time', nTime}, 'Datatype', 'double');

% 写入数据 - 数据维度已经是 [lat, lon, time]，所以直接写入
ncwrite(output_file, 'lon', lon);
ncwrite(output_file, 'lat', lat);
ncwrite(output_file, 'olr_anomaly_daily', olr_anomaly);
ncwrite(output_file, 'time', time_days_since_1970);

% 添加变量属性
ncwriteatt(output_file, 'olr_anomaly_daily', 'long_name', 'Daily Outgoing Longwave Radiation Anomaly');
ncwriteatt(output_file, 'olr_anomaly_daily', 'standard_name', 'toa_outgoing_longwave_flux_anomaly');
ncwriteatt(output_file, 'olr_anomaly_daily', 'units', 'W m-2');
ncwriteatt(output_file, 'olr_anomaly_daily', 'missing_value', single(0));
ncwriteatt(output_file, 'olr_anomaly_daily', 'valid_min', single(-300));
ncwriteatt(output_file, 'olr_anomaly_daily', 'valid_max', single(300));
ncwriteatt(output_file, 'olr_anomaly_daily', 'description', 'OLR anomaly calculated by removing 15-year (2009-2023) mean and Fourier-filtered climatology (first 3 harmonics)');

ncwriteatt(output_file, 'lon', 'long_name', 'longitude');
ncwriteatt(output_file, 'lon', 'standard_name', 'longitude');
ncwriteatt(output_file, 'lon', 'units', 'degrees_east');

ncwriteatt(output_file, 'lat', 'long_name', 'latitude');
ncwriteatt(output_file, 'lat', 'standard_name', 'latitude');
ncwriteatt(output_file, 'lat', 'units', 'degrees_north');

ncwriteatt(output_file, 'time', 'long_name', 'time');
ncwriteatt(output_file, 'time', 'standard_name', 'time');
ncwriteatt(output_file, 'time', 'units', 'days since 1970-01-01 00:00:00');
ncwriteatt(output_file, 'time', 'calendar', 'standard');

% 添加全局属性
ncwriteatt(output_file, '/', 'title', 'Daily Outgoing Longwave Radiation Anomaly (2022-2023)');
ncwriteatt(output_file, '/', 'source', 'NOAA Daily OLR CDR Product');
ncwriteatt(output_file, '/', 'institution', 'University of Maryland/ESSIC');
ncwriteatt(output_file, '/', 'history', sprintf('Created by MATLAB on %s', datestr(now, 'yyyy-mm-dd HH:MM:SS')));
ncwriteatt(output_file, '/', 'date_created', datestr(now, 'yyyy-mm-ddTHH:MM:SSZ'));
ncwriteatt(output_file, '/', 'references', 'doi:10.1175/2007JTECHA989.1, doi:10.1175/1520-0426(1989)006<0706:ATFEOL>2.0.CO;2');
ncwriteatt(output_file, '/', 'comment', 'Anomaly calculated relative to 2009-2023 climatology with Fourier filtering (first 3 harmonics retained)');
ncwriteatt(output_file, '/', 'time_coverage_start', '2022-01-01T00:00:00Z');
ncwriteatt(output_file, '/', 'time_coverage_end', '2023-12-31T23:59:59Z');
ncwriteatt(output_file, '/', 'geospatial_lat_min', '-90.0');
ncwriteatt(output_file, '/', 'geospatial_lat_max', '90.0');
ncwriteatt(output_file, '/', 'geospatial_lon_min', '0.0');
ncwriteatt(output_file, '/', 'geospatial_lon_max', '360.0');
ncwriteatt(output_file, '/', 'spatial_resolution', '1.0 degree x 1.0 degree');
ncwriteatt(output_file, '/', 'temporal_resolution', 'daily');
ncwriteatt(output_file, '/', 'climatology_period', '2009-01-01 to 2023-12-31');
ncwriteatt(output_file, '/', 'processing_method', '15-year mean removal + Fourier filtering (first 3 harmonics)');
ncwriteatt(output_file, '/', 'creator_name', 'Your Name');
ncwriteatt(output_file, '/', 'creator_email', 'your.email@example.com');
ncwriteatt(output_file, '/', 'project', 'Tropical Cyclone Freddy Analysis');

fprintf('NetCDF文件保存完成: %s\n', output_file);

% 验证输出文件
fprintf('\n验证输出文件...\n');
info = ncinfo(output_file);
fprintf('文件信息:\n');
fprintf('  维度: %s\n', strjoin({info.Dimensions.Name}, ', '));
fprintf('  变量: %s\n', strjoin({info.Variables.Name}, ', '));

% 使用 dir 函数获取文件大小
file_info = dir(output_file);
if ~isempty(file_info)
    fprintf('  文件大小: %.2f MB\n', file_info.bytes/(1024*1024));
else
    fprintf('  文件大小: 未知\n');
end

% 保存MAT格式数据（可选）
save(fullfile(output_path, 'olr_anomaly_2022_2023_final.mat'), ...
    'olr_anomaly', 'lon', 'lat', 'target_dates', 'time_days_since_1970', '-v7.3');

fprintf('\n所有处理完成！\n');
fprintf('输出文件: %s\n', output_file);
fprintf('时间范围: %s 到 %s\n', datestr(target_dates(1)), datestr(target_dates(end)));
fprintf('空间范围: %.1f°S ~ %.1f°N, %.1f°E ~ %.1f°E\n', ...
    min(lat), max(lat), min(lon), max(lon));