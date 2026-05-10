%% 清除工作区和命令窗口
clear; clc;

%% 设置路径和参数
% 输入路径
input_path = 'F:\ERA5_u_v_w_3hourly';

% 输出路径和文件名
output_dir = 'E:\Results_of_Freddy_ChenYong_version2\u_v_daily';
output_file = fullfile(output_dir, 'u_v_daily_20090101_20231231.nc');

% 创建输出目录（如果不存在）
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
    fprintf('已创建输出目录: %s\n', output_dir);
end

% 目标气压层（hPa）
target_pressure = 850;

% 经纬度范围
lat_range = [30, -30];  % 30°N ~ 30°S
lon_range = [0, 359.5]; % 0 ~ 359.5°

%% 第一步：获取所有文件列表并排序
fprintf('正在获取文件列表...\n');

% 获取所有nc文件
nc_files = dir(fullfile(input_path, '*.nc'));
file_names = {nc_files.name};

% 提取年月信息并排序
file_years = zeros(length(file_names), 1);
file_months = zeros(length(file_names), 1);

for i = 1:length(file_names)
    filename = file_names{i};
    % 提取前6位数字（年月）
    year_month_str = filename(1:6);
    file_years(i) = str2double(year_month_str(1:4));
    file_months(i) = str2double(year_month_str(5:6));
end

% 创建时间戳用于排序
file_dates = datetime(file_years, file_months, 1);

% 按时间排序
[~, sort_idx] = sort(file_dates);
sorted_files = file_names(sort_idx);

fprintf('共找到 %d 个nc文件\n', length(sorted_files));

%% 第二步：获取网格信息（从第一个文件）
first_file = fullfile(input_path, sorted_files{1});
fprintf('读取第一个文件: %s\n', first_file);

% 读取经纬度
lon = ncread(first_file, 'longitude');
lat = ncread(first_file, 'latitude');

% 计算纬度索引（30°N ~ 30°S）
lat_indices = find(lat <= lat_range(1) & lat >= lat_range(2));
lat_start = min(lat_indices);
lat_end = max(lat_indices);
lat_count = length(lat_indices);

fprintf('纬度范围: %.1f°N ~ %.1f°S\n', lat(lat_start), abs(lat(lat_end)));
fprintf('纬度索引: %d ~ %d，共 %d 个点\n', lat_start, lat_end, lat_count);

%% 第三步：预计算总天数
% 从2009年1月1日到2023年12月31日
start_date = datetime(2009, 1, 1);
end_date = datetime(2023, 12, 31);

% 计算总天数
total_days = days(end_date - start_date) + 1;
fprintf('时间范围: %s 到 %s\n', datestr(start_date), datestr(end_date));
fprintf('总天数: %d\n', total_days);

% 预分配存储空间
% 注意：我们按时间顺序存储，每次处理一个月
u_daily = nan(length(lon), lat_count, total_days, 'single');
v_daily = nan(length(lon), lat_count, total_days, 'single');

% 创建时间变量
time_days = (0:total_days-1)'; % 从第0天开始
time_dates = start_date + days(time_days);

%% 第四步：按月份处理数据
fprintf('\n开始处理数据...\n');

% 初始化时间计数器
current_day_idx = 1;

% 循环处理每个文件
for file_idx = 1:length(sorted_files)
    filename = sorted_files{file_idx};
    filepath = fullfile(input_path, filename);
    
    fprintf('处理文件 %d/%d: %s\n', file_idx, length(sorted_files), filename);
    
    try
        % 获取变量信息
        var_info = ncinfo(filepath);
        
        % 确定时间变量名
        time_var_name = '';
        for i = 1:length(var_info.Variables)
            var_name = var_info.Variables(i).Name;
            if strcmp(var_name, 'time') || strcmp(var_name, 'valid_time')
                time_var_name = var_name;
                break;
            end
        end
        
        if isempty(time_var_name)
            error('找不到时间变量');
        end
        
        % 读取时间数据
        time_data = ncread(filepath, time_var_name);
        time_units = ncreadatt(filepath, time_var_name, 'units');
        
        % 转换时间为datetime
        if contains(time_units, 'hours since 1900-01-01')
            time_dt = datetime(1900, 1, 1) + hours(time_data);
        elseif contains(time_units, 'seconds since 1970-01-01')
            time_dt = datetime(1970, 1, 1) + seconds(time_data);
        else
            error('未知的时间单位: %s', time_units);
        end
        
        % 获取唯一的日期
        unique_dates = unique(dateshift(time_dt, 'start', 'day'));
        month_days = length(unique_dates);
        
        fprintf('  该月有 %d 天，%d 个时间点\n', month_days, length(time_data));
        
        % 获取u变量信息
        u_info = ncinfo(filepath, 'u');
        
        % 确定维度顺序
        dim_names = {u_info.Dimensions.Name};
        
        % 查找气压层维度的索引
        level_dim_idx = find(strcmp(dim_names, 'level') | strcmp(dim_names, 'pressure_level'));
        lat_dim_idx = find(strcmp(dim_names, 'latitude'));
        lon_dim_idx = find(strcmp(dim_names, 'longitude'));
        time_dim_idx = find(strcmp(dim_names, 'time') | strcmp(dim_names, 'valid_time'));
        
        if isempty(level_dim_idx) || isempty(lat_dim_idx) || isempty(lon_dim_idx) || isempty(time_dim_idx)
            error('无法确定所有维度的索引');
        end
        
        % 读取气压层数据
        if any(strcmp({var_info.Variables.Name}, 'level'))
            pressure_levels = ncread(filepath, 'level');
        elseif any(strcmp({var_info.Variables.Name}, 'pressure_level'))
            pressure_levels = ncread(filepath, 'pressure_level');
        else
            error('找不到气压层变量');
        end
        
        % 找到目标气压层的索引
        [~, pressure_idx] = min(abs(pressure_levels - target_pressure));
        fprintf('  当前文件850hPa索引: %d\n', pressure_idx);
        
        % 根据维度顺序构建读取参数
        if level_dim_idx == 3 && lat_dim_idx == 2 && lon_dim_idx == 1 && time_dim_idx == 4
            % 第一种文件格式：经度 × 纬度 × 气压层 × 时间
            u_month = ncread(filepath, 'u', [1, lat_start, pressure_idx, 1], [Inf, lat_count, 1, Inf]);
            v_month = ncread(filepath, 'v', [1, lat_start, pressure_idx, 1], [Inf, lat_count, 1, Inf]);
        elseif level_dim_idx == 3 && lat_dim_idx == 2 && lon_dim_idx == 4 && time_dim_idx == 1
            % 第二种可能：时间 × 纬度 × 气压层 × 经度
            u_month = ncread(filepath, 'u', [1, lat_start, pressure_idx, 1], [Inf, lat_count, 1, Inf]);
            v_month = ncread(filepath, 'v', [1, lat_start, pressure_idx, 1], [Inf, lat_count, 1, Inf]);
            % 调整维度顺序
            u_month = permute(u_month, [4, 2, 3, 1]);
            v_month = permute(v_month, [4, 2, 3, 1]);
        else
            error('未知的维度顺序');
        end
        
        % 压缩气压层维度
        u_month = squeeze(u_month);
        v_month = squeeze(v_month);
        
        % 检查维度
        if size(u_month, 1) ~= length(lon) || size(u_month, 2) ~= lat_count
            error('维度不匹配: u_month大小 = %s, 期望 = [%d, %d, %d]', ...
                mat2str(size(u_month)), length(lon), lat_count, size(u_month, 3));
        end
        
        % 按天计算平均值
        fprintf('  按天计算平均值...\n');
        
        for day_idx = 1:month_days
            current_date = unique_dates(day_idx);
            
            % 找到当天的所有时间点
            day_mask = dateshift(time_dt, 'start', 'day') == current_date;
            day_time_points = sum(day_mask);
            
            if day_time_points == 0
                fprintf('警告: 日期 %s 没有数据\n', datestr(current_date));
                continue;
            end
            
            % 提取当天的数据
            u_day_data = u_month(:, :, day_mask);
            v_day_data = v_month(:, :, day_mask);
            
            % 计算日平均值（忽略NaN）
            u_daily_mean = mean(u_day_data, 3, 'omitnan');
            v_daily_mean = mean(v_day_data, 3, 'omitnan');
            
            % 存储结果
            u_daily(:, :, current_day_idx) = u_daily_mean;
            v_daily(:, :, current_day_idx) = v_daily_mean;
            
            current_day_idx = current_day_idx + 1;
        end
        
        fprintf('  已处理 %d 天\n', month_days);
        clear u_month v_month;
        
    catch ME
        fprintf('处理文件 %s 时出错: %s\n', filename, ME.message);
        fprintf('跳过此文件，继续处理下一个文件\n');
        continue;
    end
    
    % 显示进度
    if mod(file_idx, 10) == 0
        fprintf('已完成 %d/%d 个文件\n', file_idx, length(sorted_files));
    end
end

%% 第五步：创建输出NetCDF文件
fprintf('\n创建输出文件: %s\n', output_file);

% 删除已存在的文件（如果存在）
if exist(output_file, 'file')
    delete(output_file);
end

% 创建NetCDF文件
nccreate(output_file, 'longitude', 'Dimensions', {'longitude', length(lon)}, 'Datatype', 'single');
nccreate(output_file, 'latitude', 'Dimensions', {'latitude', lat_count}, 'Datatype', 'single');
nccreate(output_file, 'time', 'Dimensions', {'time', total_days}, 'Datatype', 'double');

nccreate(output_file, 'u_daily_mean', ...
    'Dimensions', {'longitude', length(lon), 'latitude', lat_count, 'time', total_days}, ...
    'Datatype', 'single', ...
    'DeflateLevel', 4);

nccreate(output_file, 'v_daily_mean', ...
    'Dimensions', {'longitude', length(lon), 'latitude', lat_count, 'time', total_days}, ...
    'Datatype', 'single', ...
    'DeflateLevel', 4);

% 写入经纬度数据
fprintf('写入经纬度数据...\n');
ncwrite(output_file, 'longitude', lon);
ncwrite(output_file, 'latitude', lat(lat_start:lat_end));

% 写入时间数据
fprintf('写入时间数据...\n');
ncwrite(output_file, 'time', time_days);

% 添加属性
fprintf('添加属性...\n');
ncwriteatt(output_file, 'longitude', 'units', 'degrees_east');
ncwriteatt(output_file, 'longitude', 'long_name', 'longitude');
ncwriteatt(output_file, 'longitude', 'standard_name', 'longitude');

ncwriteatt(output_file, 'latitude', 'units', 'degrees_north');
ncwriteatt(output_file, 'latitude', 'long_name', 'latitude');
ncwriteatt(output_file, 'latitude', 'standard_name', 'latitude');

ncwriteatt(output_file, 'time', 'units', 'days since 2009-01-01 00:00:00');
ncwriteatt(output_file, 'time', 'long_name', 'time');
ncwriteatt(output_file, 'time', 'calendar', 'gregorian');

ncwriteatt(output_file, 'u_daily_mean', 'units', 'm s^-1');
ncwriteatt(output_file, 'u_daily_mean', 'long_name', 'Daily mean eastward wind at 850 hPa');
ncwriteatt(output_file, 'u_daily_mean', 'standard_name', 'eastward_wind');
ncwriteatt(output_file, 'u_daily_mean', 'pressure_level', target_pressure);
ncwriteatt(output_file, 'u_daily_mean', 'coordinates', 'longitude latitude time');
ncwriteatt(output_file, 'u_daily_mean', 'missing_value', NaN('single'));

ncwriteatt(output_file, 'v_daily_mean', 'units', 'm s^-1');
ncwriteatt(output_file, 'v_daily_mean', 'long_name', 'Daily mean northward wind at 850 hPa');
ncwriteatt(output_file, 'v_daily_mean', 'standard_name', 'northward_wind');
ncwriteatt(output_file, 'v_daily_mean', 'pressure_level', target_pressure);
ncwriteatt(output_file, 'v_daily_mean', 'coordinates', 'longitude latitude time');
ncwriteatt(output_file, 'v_daily_mean', 'missing_value', NaN('single'));

% 添加全局属性
ncwriteatt(output_file, '/', 'title', 'Daily mean wind components at 850 hPa from ERA5');
ncwriteatt(output_file, '/', 'source', 'ERA5 reanalysis');
ncwriteatt(output_file, '/', 'institution', 'European Centre for Medium-Range Weather Forecasts');
ncwriteatt(output_file, '/', 'history', sprintf('Created by MATLAB on %s', datestr(now)));
ncwriteatt(output_file, '/', 'Conventions', 'CF-1.7');
ncwriteatt(output_file, '/', 'creation_date', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
ncwriteatt(output_file, '/', 'time_coverage_start', datestr(start_date, 'yyyy-mm-dd'));
ncwriteatt(output_file, '/', 'time_coverage_end', datestr(end_date, 'yyyy-mm-dd'));
ncwriteatt(output_file, '/', 'latitude_range', sprintf('%.1f to %.1f degrees_north', lat(lat_start), lat(lat_end)));
ncwriteatt(output_file, '/', 'longitude_range', sprintf('%.1f to %.1f degrees_east', lon(1), lon(end)));
ncwriteatt(output_file, '/', 'pressure_level', sprintf('%d hPa', target_pressure));
ncwriteatt(output_file, '/', 'spatial_resolution', '0.5 x 0.5 degrees');
ncwriteatt(output_file, '/', 'temporal_resolution', 'daily mean');

%% 第六步：写入u和v的日平均值数据
fprintf('写入u和v的日平均值数据...\n');

% 分块写入以避免内存问题
chunk_size = 100; % 每次写入100天
num_chunks = ceil(total_days / chunk_size);

for chunk_idx = 1:num_chunks
    start_day = (chunk_idx - 1) * chunk_size + 1;
    end_day = min(chunk_idx * chunk_size, total_days);
    chunk_days = end_day - start_day + 1;
    
    fprintf('  写入第 %d 块: 第 %d 到 %d 天\n', chunk_idx, start_day, end_day);
    
    % 提取当前块的数据
    u_chunk = u_daily(:, :, start_day:end_day);
    v_chunk = v_daily(:, :, start_day:end_day);
    
    % 写入数据
    ncwrite(output_file, 'u_daily_mean', u_chunk, [1, 1, start_day]);
    ncwrite(output_file, 'v_daily_mean', v_chunk, [1, 1, start_day]);
    
    % 显示进度
    if mod(chunk_idx, 10) == 0
        fprintf('  已完成 %.1f%%\n', (chunk_idx/num_chunks)*100);
    end
end

%% 第七步：验证输出文件
fprintf('\n验证输出文件...\n');
try
    out_info = ncinfo(output_file);
    fprintf('输出文件创建成功！\n');
    fprintf('文件大小: %.2f MB\n', out_info.FileSize/(1024^2));
    
    % 显示变量信息
    fprintf('\n输出文件变量信息:\n');
    for i = 1:length(out_info.Variables)
        var_name = out_info.Variables(i).Name;
        var_size = out_info.Variables(i).Size;
        fprintf('  %s: %s\n', var_name, mat2str(var_size));
    end
    
    % 读取并显示时间范围
    out_time = ncread(output_file, 'time');
    fprintf('\n时间范围: 第 %.0f 天 到 第 %.0f 天\n', min(out_time), max(out_time));
    fprintf('总天数: %d\n', length(out_time));
    
catch ME
    fprintf('验证文件时出错: %s\n', ME.message);
end

%% 第八步：清理和总结
fprintf('\n处理完成！\n');
fprintf('输出文件: %s\n', output_file);
fprintf('数据维度:\n');
fprintf('  经度: %d 个点 (%.1f°E 到 %.1f°E)\n', length(lon), lon(1), lon(end));
fprintf('  纬度: %d 个点 (%.1f°N 到 %.1f°S)\n', lat_count, lat(lat_start), abs(lat(lat_end)));
fprintf('  时间: %d 天 (%s 到 %s)\n', total_days, datestr(time_dates(1)), datestr(time_dates(end)));
fprintf('  气压层: %d hPa\n', target_pressure);

% 显示内存使用情况
mem_info = memory;
fprintf('内存使用情况: %.2f GB\n', mem_info.MemUsedMATLAB/(1024^3));

fprintf('\n所有处理已完成！\n');