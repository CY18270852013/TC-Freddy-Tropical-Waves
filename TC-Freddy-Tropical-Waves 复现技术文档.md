# TC\-Freddy\-Tropical\-Waves 复现技术文档

**论文题目**：热带波动对破纪录热带气旋 Freddy 生成的影响研究
**作者**：陈勇
**版本**：v1\.0
**最后更新**：2026 年 5 月 11 日

---

## 目录

1. \[项目简介\]\(\#1\-项目简介\)

2. \[环境配置要求\]\(\#2\-环境配置要求\)

3. \[数据下载步骤\]\(\#3\-数据下载步骤\)

4. \[数据处理流程\]\(\#4\-数据处理流程\)

5. \[代码实现详解\]\(\#5\-代码实现详解\)

6. \[实验复现步骤\]\(\#6\-实验复现步骤\)

7. \[绘图方法详解\]\(\#7\-绘图方法详解\)

8. \[结果验证\]\(\#8\-结果验证\)

9. \[常见问题与解决方案\]\(\#9\-常见问题与解决方案\)

10. \[引用说明\]\(\#10\-引用说明\)

---

## 1\. 项目简介

### 1\.1 研究背景

热带气旋 Freddy（2023）是有记录以来持续时间最长、累积气旋能量（ACE）最高的热带气旋之一，在南印度洋经历了两次增强 \- 减弱 \- 再增强的过程，对马达加斯加、莫桑比克等国造成了严重影响。本研究旨在揭示热带波动（MJO、MRG、ER、Kelvin 波）在 Freddy 生成过程中的作用机制。

### 1\.2 研究目的

- 定量分析四种热带波动（MJO、MRG、ER、Kelvin）对 Freddy 生成环境的贡献

- 揭示涡旋拉伸（vortex stretching）机制在热带气旋生成中的作用

- 建立热带波动与热带气旋生成之间的定量联系

### 1\.3 研究意义

本研究对于理解热带气旋生成的动力学机制、提高热带气旋预报准确率具有重要的科学价值和应用意义。通过量化不同热带波动的相对贡献，可以为业务预报提供物理依据。

### 1\.4 研究方法概述

本研究采用**时空滤波**技术从观测数据中分离不同尺度的热带波动信号，结合**动力诊断**方法分析涡旋拉伸和对流激发机制。主要技术路线包括：

1. 数据预处理：计算气候态和异常场

2. 波动分离：使用 NCL 进行 Wheeler\-Kiladis 滤波

3. 动力诊断：计算涡旋拉伸项和水汽辐合

4. 统计分析：量化各波动的相对贡献

5. 可视化：生成 Hovmöller 图、空间分布图、时间序列图

---

## 2\. 环境配置要求

### 2\.1 软件环境

|软件|版本要求|用途|
|---|---|---|
|Python|3\.8\+|数据处理与绘图|
|MATLAB|R2020a\+|批量数据处理|
|NCL|6\.6\.2\+|热带波动时空滤波|
|Git|任意|版本控制|

### 2\.2 Python 依赖库

```bash
# 核心科学计算库
numpy>=1.21.0
pandas>=1.3.0
xarray>=0.19.0
netCDF4>=1.5.7
scipy>=1.7.0

# 气象专用库
cartopy>=0.20.0
metpy>=1.2.0

# 可视化库
matplotlib>=3.4.0
seaborn>=0.11.0

# 其他工具
tqdm>=4.62.0
```

### 2\.3 安装步骤

#### 2\.3\.1 使用 conda 安装（推荐）

```bash
# 创建虚拟环境
conda create -n tc-freddy python=3.9
conda activate tc-freddy

# 安装核心依赖
conda install -c conda-forge numpy pandas xarray netCDF4 scipy
conda install -c conda-forge cartopy matplotlib metpy
conda install -c conda-forge tqdm
```

#### 2\.3\.2 使用 pip 安装

```bash
pip install numpy pandas xarray netCDF4 scipy
pip install cartopy matplotlib metpy
pip install tqdm
```

#### 2\.3\.3 NCL 安装

```bash
# 使用conda安装NCL
conda install -c conda-forge ncl

# 验证安装
ncl -V
```

---

## 3\. 数据下载步骤

### 3\.1 数据源概览

|数据类型|数据源|时间分辨率|空间分辨率|时间范围|
|---|---|---|---|---|
|降水数据|GPM IMERG|30 分钟 / 6 小时 / 日|0\.1°|2009\-2023|
|射出长波辐射|NOAA OLR|日|2\.5°|2009\-2023|
|气象场数据|ERA5|3 小时 / 6 小时|0\.25°|2009\-2023|
|热带气旋路径|IBTrACS|6 小时|\-|2023|

### 3\.2 GPM 降水数据下载

**官方网站**：[https://gpm\.nasa\.gov/data\-access](https://gpm.nasa.gov/data-access)

```bash
# 使用wget批量下载（需要注册Earthdata账号）
wget --user=YOUR_USERNAME --password=YOUR_PASSWORD \
     "https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGHH.07/2023/" \
     -r -np -A "*.HDF5"

# 或使用Python脚本下载
import requests
from datetime import datetime, timedelta

base_url = "https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGHH.07"
session = requests.Session()
session.auth = ('YOUR_USERNAME', 'YOUR_PASSWORD')

start_date = datetime(2023, 1, 1)
end_date = datetime(2023, 3, 31)

current_date = start_date
while current_date <= end_date:
    year = current_date.year
    doy = current_date.timetuple().tm_yday
    url = f"{base_url}/{year}/{doy:03d}/"
    # 下载该日所有文件
    current_date += timedelta(days=1)
```

### 3\.3 ERA5 数据下载

**官方网站**：[https://cds\.climate\.copernicus\.eu/](https://cds.climate.copernicus.eu/)

```python
import cdsapi

c = cdsapi.Client()

# 下载850hPa风场、温度、湿度数据
c.retrieve(
    'reanalysis-era5-pressure-levels',
    {
        'product_type': 'reanalysis',
        'variable': [
            'u_component_of_wind', 'v_component_of_wind',
            'temperature', 'specific_humidity',
            'divergence', 'relative_humidity'
        ],
        'pressure_level': ['850', '200'],
        'year': ['2023'],
        'month': ['01', '02', '03'],
        'day': [f'{i:02d}' for i in range(1, 32)],
        'time': [f'{i:02d}:00' for i in range(0, 24, 6)],
        'format': 'netcdf',
    },
    'ERA5_6hourly_2023.nc'
)
```

### 3\.4 OLR 数据下载

**官方网站**：[https://www\.esrl\.noaa\.gov/psd/](https://www.esrl.noaa.gov/psd/)

```bash
# NOAA OLR日数据
wget ftp://ftp.cdc.noaa.gov/Datasets/interp_OLR/olr.day.mean.nc

# 或分年度下载
for year in {2009..2023}; do
    wget "https://downloads.psl.noaa.gov/Datasets/interp_OLR/olr-daily_v01r02_${year}0101_${year}1231.nc"
done
```

### 3\.5 IBTrACS 数据下载

**官方网站**：[https://www\.ncei\.noaa\.gov/products/international\-best\-track\-archive](https://www.ncei.noaa.gov/products/international-best-track-archive)

```bash
# 南印度洋区域数据
wget "https://www.ncei.noaa.gov/data/international-best-track-archive-for-climate-stewardship-ibtracs/v04r01/access/netcdf/IBTrACS.SI.v04r01.nc"
```

### 3\.6 数据目录结构建议

```Plain Text
Data/
├── GPM/
│   ├── 30min/
│   ├── 6hourly/
│   └── daily/
├── ERA5/
│   ├── uv_3hourly/
│   ├── uv_6hourly/
│   ├── divergence/
│   └── VIMD/
├── OLR/
│   └── daily/
└── IBTrACS/
    └── IBTrACS.SI.v04r01.nc
```

---

## 4\. 数据处理流程

### 4\.1 处理流程总览

```Plain Text
原始数据 → 时间聚合 → 气候态计算 → 异常场计算 → 波动滤波 → 诊断量计算 → 结果分析
    ↓          ↓          ↓           ↓          ↓          ↓
  GPM/      30min→     15年       原始-气候   Wheeler-   涡旋拉伸
  ERA5/     6hourly    日循环      态场      Kiladis    水汽辐合
  OLR/      →daily     拟合                   滤波      能量转换
```

### 4\.2 GPM 降水数据处理

#### 4\.2\.1 30 分钟到 6 小时聚合

**MATLAB 脚本**：`GPM\_6hourly\_Cumulative\_Precipitation\.m`

```matlab
% 输入：30分钟GPM数据
% 输出：6小时累积降水数据

% 数学原理：
% P_6h = Σ P_30min × 0.5小时
% 其中0.5小时是30分钟数据的时间间隔

data_dir = '\DS1821\Observation\GPM';
time_range = datetime(2009,1,1):hours(6):datetime(2023,12,31,23,59,59);

for t = 1:length(time_range)
    % 读取该6小时窗口内的所有30分钟数据
    files = get_files_in_window(time_range(t), time_range(t)+hours(6));
    
    % 累积降水计算
    precip_6h = zeros(lon_size, lat_size);
    for f = 1:length(files)
        data = read_gpm_file(files{f});
        precip_6h = precip_6h + data.precipitation * 0.5;  % mm/h × h = mm
    end
    
    % 保存为NetCDF
    save_to_netcdf(precip_6h, time_range(t), ['GPM_6hourly_', datestr(time_range(t), 'yyyymmddHHMMSS'), '.nc']);
end
```

**物理意义**：将高时间分辨率的瞬时降水率转换为累积降水量，便于与其他 6 小时分辨率的气象场匹配。

#### 4\.2\.2 气候态与异常场计算

**MATLAB 脚本**：`calculate\_GPM\_anomaly\_6hourly\.m`

```matlab
% 输入：2009-2023年6小时GPM数据
% 输出：异常场数据

% 数学原理：
% 1. 构建15年的日循环气候态
% 2. 使用傅里叶拟合平滑气候态
% 3. 异常场 = 原始场 - 拟合后的气候态

% 步骤1：读取所有数据
all_data = read_all_gpm_6hourly();

% 步骤2：计算日循环气候态（每年同一天的平均值）
climatology = zeros(366, lon_size, lat_size);
for day = 1:366
    indices = get_day_of_year_indices(all_data.time, day);
    climatology(day,:,:) = mean(all_data.precip(:,:,indices), 3);
end

% 步骤3：傅里叶拟合（保留前5个谐波）
% P_clim_fit(t) = a0 + Σ(an*cos(nωt) + bn*sin(nωt)), n=1..5
fit_climatology = fourier_fit(climatology, 5);

% 步骤4：计算异常场
anomaly = zeros(size(all_data.precip));
for t = 1:size(all_data.precip, 3)
    day_of_year = dayofyear(all_data.time(t));
    anomaly(:,:,t) = all_data.precip(:,:,t) - squeeze(fit_climatology(day_of_year,:,:));
end

% 步骤5：标准化
mean_precip = mean(anomaly, 3);
std_precip = std(anomaly, 0, 3);
normalized_precip = (anomaly - mean_precip) ./ std_precip;
```

**物理意义**：

- 去除季节循环信号，突出天气尺度扰动

- 标准化使得不同空间位置的异常具有可比性

- 傅里叶拟合避免了气候态的不连续性

### 4\.3 ERA5 风场数据处理

#### 4\.3\.1 3 小时到日平均

**MATLAB 脚本**：`transfer\_uv\_3hourly\_to\_daily\.m`

```matlab
% 输入：3小时ERA5 u/v风场数据
% 输出：日平均风场数据

% 数学原理：
% u_daily = (u_00 + u_03 + u_06 + u_09 + u_12 + u_15 + u_18 + u_21) / 8

data_dir = 'F:\ERA5_u_v_w_3hourly';
all_u = [];
all_v = [];
all_time = [];

for year = 2009:2023
    for month = 1:12
        files = get_monthly_files(year, month);
        for day = 1:eomday(year, month)
            % 读取当日8个时次的数据
            daily_u = zeros(lon_size, lat_size, 8);
            daily_v = zeros(lon_size, lat_size, 8);
            
            for h = 1:8
                data = read_era5_file(files{h});
                daily_u(:,:,h) = data.u;
                daily_v(:,:,h) = data.v;
            end
            
            % 日平均
            all_u(:,:,end+1) = mean(daily_u, 3);
            all_v(:,:,end+1) = mean(daily_v, 3);
            all_time(end+1) = datetime(year, month, day);
        end
    end
end

% 保存为NetCDF
save_netcdf('u_v_daily_20090101_20231231.nc', all_u, all_v, all_time);
```

#### 4\.3\.2 风场异常计算

**MATLAB 脚本**：`calculate\_ERA5\_u\_v\_anomaly\_daily\.m`

处理流程与 GPM 数据相同：

1. 计算 15 年日循环气候态

2. 傅里叶拟合平滑

3. 计算异常场

4. 标准化处理

### 4\.4 OLR 数据处理

**MATLAB 脚本**：`calculate\_OLR\_anomaly\_daily\.m`

OLR（射出长波辐射）是对流活动的良好指示器：

- 低 OLR 值 = 强对流活动（深云）

- 高 OLR 值 = 弱对流活动（晴空）

处理步骤：

1. 读取 2009\-2023 年日 OLR 数据

2. 计算气候态和傅里叶拟合

3. 计算异常场（OLR\&\#39; = OLR \- OLR\_clim）

4. 负异常表示对流增强

### 4\.5 垂直积分水汽辐合（VIMD）计算

**MATLAB 脚本**：`calculate\_VIMD\_6hourly\.m`

```matlab
% 数学原理：
% VIMD = -∫(∇·(qV)) dp/g
% 其中：
%   q = 比湿
%   V = 风矢量 (u, v)
%   ∇· = 水平散度算子
%   dp = 气压层厚度
%   g = 重力加速度

% 积分层次：1000hPa到100hPa
levels = [1000, 950, 900, 850, 800, 750, 700, 650, 600, 550, 500, 450, 400, 350, 300, 250, 200, 150, 100];

for t = 1:n_time
    vimd = zeros(lon_size, lat_size);
    
    for k = 1:length(levels)-1
        % 计算该层的水汽通量散度
        q = read_specific_humidity(levels(k), t);
        u = read_u_wind(levels(k), t);
        v = read_v_wind(levels(k), t);
        
        % 计算散度 ∇·(qV)
        div_qV = calculate_divergence(q.*u, q.*v, lon, lat);
        
        % 垂直积分（梯形积分法）
        dp = (levels(k+1) - levels(k)) * 100;  % hPa to Pa
        vimd = vimd - div_qV * dp / 9.81;  % 负号表示辐合为正
    end
    
    % 保存结果
    VIMD(:,:,t) = vimd;
end
```

**物理意义**：
VIMD 表示整层大气的水汽辐合，是热带气旋生成的关键因子。正值表示有水汽向该区域辐合，有利于对流发展和气旋生成。

### 4\.6 散度与涡旋拉伸计算

**MATLAB 脚本**：`calculate\_divergence\_anomaly\_6hourly\.m`

```matlab
% 水平散度计算：
% δ = ∂u/∂x + ∂v/∂y

% 相对涡度计算：
% ζ = ∂v/∂x - ∂u/∂y

% 涡旋拉伸项：
% ω∂ζ/∂z = 垂直速度 × 相对涡度的垂直梯度
% 这是热带气旋生成中涡度增长的关键机制

for t = 1:n_time
    % 850hPa风场
    u_850 = u(:,:,find(levels==850), t);
    v_850 = v(:,:,find(levels==850), t);
    
    % 200hPa风场
    u_200 = u(:,:,find(levels==200), t);
    v_200 = v(:,:,find(levels==200), t);
    
    % 计算850hPa散度
    div_850 = calculate_divergence(u_850, v_850, lon, lat);
    
    % 计算相对涡度垂直梯度
    zeta_850 = calculate_vorticity(u_850, v_850, lon, lat);
    zeta_200 = calculate_vorticity(u_200, v_200, lon, lat);
    dzeta_dp = (zeta_200 - zeta_850) / ((200-850)*100);  % Pa^-1
    
    % 计算垂直速度（从连续方程）
    omega = 850*100 * div_850;  % 简化计算
    
    % 涡旋拉伸项
    vortex_stretching = omega .* dzeta_dp;
end
```

---

## 5\. 代码实现详解

### 5\.1 代码目录结构

```Plain Text
TC-Freddy-Tropical-Waves/
├── Python_codes/
│   ├── Freddy_&_Dingani_Tracks_(2023).py    # 气旋路径绘制
│   ├── mean_specific_humidity_at_850_Pa.py  # 850hPa比湿图
│   ├── Monthly_Mean_Vertical_Wind_Shear.py  # 垂直风切变
│   ├── sst_with_full_track.py               # 海温与路径
│   ├── wind_and_precipitation.py            # 风场与降水
│   └── Daily_Precipitation_and_850_hPa_Winds/  # 逐日演变图
├── ERA5_divergence/                         # 散度分析代码
├── ERA5_relative_humidity/                  # 湿度分析代码
├── ERA5_uv/                                 # 风场分析代码
│   ├── 6hourly/
│   └── daily/
├── ERA5_VIMD/                               # VIMD分析代码
├── GPM_precipitation/                       # 降水分析代码
└── OLR/                                     # OLR分析代码
```

### 5\.2 Python 代码详解

#### 5\.2\.1 热带气旋路径绘制

**文件**：`Freddy\_\&amp;\_Dingani\_Tracks\_\(2023\)\.py`

```python
import xarray as xr
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import numpy as np

def find_storm_index(dataset, target_sid):
    """
    在IBTrACS数据中查找特定风暴的索引
    
    参数:
        dataset: IBTrACS NetCDF数据集
        target_sid: 风暴唯一标识符（bytes）
    
    返回:
        风暴索引，未找到返回None
        
    数据结构说明:
        IBTrACS数据使用sid字段唯一标识每个风暴，
        格式为：YYYYDDD{S}{lon}{lat}
    """
    sids = dataset['sid'].values
    for i, sid in enumerate(sids):
        if sid == target_sid:
            return i
    return None

def extract_track(dataset, idx):
    """
    提取风暴路径数据
    
    数学原理:
        过滤无效数据点（lat=-9999, lon=-9999）
        只保留有效的经纬度和时间记录
    """
    time = dataset['time'][idx].values
    lat = dataset['lat'][idx].values
    lon = dataset['lon'][idx].values
    valid = (lat > -90) & (lon > -180) & (~np.isnat(time))
    return time[valid], lat[valid], lon[valid]

# 主程序
ds = xr.open_dataset(r"D:\Freddy_ChenYong\Data\IBTrACS.SI.v04r01.nc")
freddy_sid = b'2023036S12117'  # Freddy: 2023年第36天, 南纬12°, 东经117°
dingani_sid = b'2023032S12091'

freddy_idx = find_storm_index(ds, freddy_sid)
freddy_time, freddy_lat, freddy_lon = extract_track(ds, freddy_idx)
```

**关键技术点**：

- 使用 Cartopy 进行地图投影

- 路径日期标注算法（间隔 2 天标注）

- 标记点与文字偏移算法

#### 5\.2\.2 垂直风切变计算

**文件**：`Monthly\_Mean\_Vertical\_Wind\_Shear\.py`

```python
def calculate_vertical_shear(ds):
    """
    计算200-850hPa垂直风切变
    
    数学原理:
        VWS = √[(u200 - u850)² + (v200 - v850)²]
    
    物理意义:
        垂直风切变是热带气旋发展的关键环境因子
        VWS < 10 m/s: 有利于发展
        VWS > 12 m/s: 抑制发展
    """
    u200 = ds['u'].sel(pressure_level=200, method='nearest')
    v200 = ds['v'].sel(pressure_level=200, method='nearest')
    u850 = ds['u'].sel(pressure_level=850, method='nearest')
    v850 = ds['v'].sel(pressure_level=850, method='nearest')
    return np.sqrt((u200 - u850)**2 + (v200 - v850)**2)
```

#### 5\.2\.3 海温与路径叠加

**文件**：`sst\_with\_full\_track\.py`

```python
def get_sst_data(ds):
    """
    提取海表面温度数据
    
    单位转换:
        ERA5温度单位为K，转换为°C需减273.15
        使用1000hPa温度近似代表SST
    """
    sst = ds['t'].sel(pressure_level=1000, method='nearest') - 273.15
    return sst
```

**关键技术点**：

- 使用`patheffects`实现路径的白边描边，提高可读性

- 自定义颜色映射（18°C\-30°C）

- 26°C 等温线是热带气旋发展的阈值

#### 5\.2\.4 逐日降水与风场演变

**文件**：`wind\_and\_precipitation\.py`

```python
def process_era5_data(ds_era5, target_date):
    """
    处理ERA5日平均风场数据
    
    坐标转换:
        将0-360°经度转换为-180-180°
        确保与GPM数据的坐标系统一
    """
    ds_era5 = ds_era5.sel(pressure_level=850.0)
    ds_era5 = ds_era5.assign_coords(
        longitude=(((ds_era5.longitude + 180) % 360) - 180)
    )
    ds_era5 = ds_era5.sortby('longitude')
    
    daily_u = ds_era5['u'].resample(valid_time='1D').mean()
    daily_v = ds_era5['v'].resample(valid_time='1D').mean()
    
    return daily_u.sel(valid_time=target_date), daily_v.sel(valid_time=target_date)
```

**关键技术点**：

- 风矢量稀疏化（skip=8）避免过密

- 矢量比例尺设置（quiverkey）

- 降水与风场的多源数据融合

### 5\.3 MATLAB 代码详解

#### 5\.3\.1 波动滤波 NCL 脚本

**原理**：Wheeler\-Kiladis 时空滤波

```ncl
; 波数-频率滤波参数设置
; MJO: 波数1-3，周期30-90天
; ER: 波数1-5，周期10-20天
; MRG: 波数2-10，周期2-10天
; Kelvin: 波数1-14，周期2.5-20天

begin
    ; 读取异常场数据
    f = addfile("GPM_anomaly_6hourly.nc", "r")
    precip = f->anomaly
    
    ; 时空傅里叶变换
    precip_fft = fft(precip, 3)  ; 时间维
    precip_fft = fft(precip_fft, 1)  ; 经度维
    
    ; 构建滤波器
    filter = new(dimsizes(precip_fft), float)
    
    ; MJO滤波参数
    k_min = 1
    k_max = 3
    T_min = 30
    T_max = 90
    
    ; 应用滤波器
    precip_filtered = ifft(precip_fft * filter, 1)
    precip_filtered = ifft(precip_filtered, 3)
    
    ; 保存结果
    system("rm -f GPM_anomaly_for_MJO_6hourly.nc")
    fout = addfile("GPM_anomaly_for_MJO_6hourly.nc", "c")
    fout->precip_MJO = precip_filtered
end
```

**数学原理**：

1. 对经度和时间维度进行二维傅里叶变换

2. 在波数 \- 频率域内保留对应波动的能量

3. 逆傅里叶变换回物理空间

#### 5\.3\.2 Hovmöller 图绘制

**文件**：`plot\_mjo\_hovmoller\_diagram\.m`

```matlab
function plot_hovmoller(data, lat_range, title_str, save_name)
    % 纬度平均：10°S-10°N
    lat_indices = find(lat >= lat_range(1) & lat <= lat_range(2));
    data_lat_mean = mean(data(:, lat_indices, :), 2);
    
    % 绘制时间-经度剖面图
    figure('Position', [100, 100, 800, 600])
    contourf(lon, time, squeeze(data_lat_mean)', 20, 'LineStyle', 'none')
    colorbar
    xlabel('Longitude (°E)')
    ylabel('Date')
    title(title_str)
    
    % 颜色设置：蓝负红正（异常场）
    colormap(redblue_colormap)
    caxis([-5, 5])  % 单位：mm/day
    
    saveas(gcf, save_name)
end
```

**物理意义**：
Hovmöller 图展示波动的东传 / 西传特性：

- Kelvin 波：东传，斜率为正

- ER/MRG 波：西传，斜率为负

- MJO：东传，速度较慢

---

## 6\. 实验复现步骤

### 6\.1 复现流程总览

```Plain Text
步骤1: 环境配置 → 步骤2: 数据下载 → 步骤3: 数据预处理
     ↓                    ↓                    ↓
步骤6: 结果验证 ← 步骤5: 绘图生成 ← 步骤4: 波动分离与诊断
```

### 6\.2 详细复现步骤

#### 步骤 1：克隆仓库并配置环境

```bash
# 克隆GitHub仓库
git clone https://github.com/CY18270852013/TC-Freddy-Tropical-Waves.git
cd TC-Freddy-Tropical-Waves

# 创建并激活Python环境
conda create -n tc-freddy python=3.9
conda activate tc-freddy

# 安装依赖
pip install numpy pandas xarray netCDF4 scipy cartopy matplotlib
```

#### 步骤 2：下载所有原始数据

按照\[第 3 章\]\(\#3\-数据下载步骤\)的说明下载以下数据：

- GPM IMERG 30 分钟数据（2009\-2023）

- ERA5 3 小时 / 6 小时压力层数据（2009\-2023）

- NOAA OLR 日数据（2009\-2023）

- IBTrACS 热带气旋路径数据（2023）

#### 步骤 3：数据预处理（MATLAB）

```matlab
% ===== GPM数据处理 =====
% 30分钟→6小时聚合
run('GPM_6hourly_Cumulative_Precipitation.m')

% 计算异常场
run('calculate_GPM_anomaly_6hourly.m')

% 日数据处理
run('calculate_GPM_precipitation_anomaly_daily.m')

% ===== ERA5数据处理 =====
% 3小时→日平均
run('transfer_uv_3hourly_to_daily.m')

% 日异常场计算
run('calculate_ERA5_u_v_anomaly_daily.m')

% 6小时异常场计算
run('calculate_uv_anomaly_6hourly.m')

% VIMD计算
run('calculate_VIMD_6hourly.m')
run('calculate_VIMD_anomaly_6hourly.m')

% 散度计算
run('calculate_divergence_anomaly_6hourly.m')

% ===== OLR数据处理 =====
run('calculate_OLR_anomaly_daily.m')
```

#### 步骤 4：热带波动滤波（NCL）

```bash
# GPM降水波动分离
ncl wave_filter_for_GPM_anomaly_6hourly.ncl
ncl wave_filter_for_GPM_anomaly_daily.ncl

# 风场波动分离
ncl wave_filter_for_u_v_anomaly_6hourly.ncl
ncl wave_filter_for_u_v_anomaly_daily.ncl

# VIMD波动分离
ncl wave_filter_for_VIMD_anomaly_6hourly.ncl

# 散度波动分离
ncl wave_filter_for_divergence_anomaly_6hourly.ncl

# OLR波动分离
ncl wave_filter_for_OLR_anomaly_daily.ncl
```

#### 步骤 5：生成所有图表

```bash
# Python图表生成
cd Python_codes
python Freddy_\&_Dingani_Tracks_\(2023\).py
python mean_specific_humidity_at_850\ _Pa.py
python Monthly_Mean_Vertical_Wind_Shear.py
python sst_with_full_track.py
python wind_and_precipitation.py

# MATLAB图表生成
# 运行所有plot_*.m脚本
```

#### 步骤 6：结果验证

对比生成的图片与论文中的图表，检查：

1. 波动信号的传播方向和速度是否正确

2. 异常场的空间分布是否合理

3. 时间序列的峰值是否与 Freddy 生成时间对应

4. 各波动贡献的定量结果是否一致

---

## 7\. 绘图方法详解

### 7\.1 论文图表清单

|图号|图表名称|生成脚本|
|---|---|---|
|Fig\.1|Freddy \&amp; Dingani 路径图|`Freddy\_\&amp;\_Dingani\_Tracks\_\(2023\)\.py`|
|Fig\.2|四种波动 Hovmöller 图|`plot\_\*\_hovmoller\_diagram\.m`|
|Fig\.3|降水与风场异常空间分布|`plot\_precip\_uv\_\*\.m`|
|Fig\.4|Freddy 生成区 Hovmöller 图|`plot\_precip\_hovmuller\_6hourly\.m`|
|Fig\.5|各变量波动贡献分解|`plot\_\*\_freddy\_box\.m`|
|Fig\.6|海温与垂直风切变|`sst\_with\_full\_track\.py`, `Monthly\_Mean\_Vertical\_Wind\_Shear\.py`|
|Fig\.7|涡旋拉伸时间序列|`plot\_div\_vortex\_stretching\_\*\.m`|
|Fig\.8|相对湿度垂直剖面|`plot\_q\_freddy\_box\.m`|

### 7\.2 关键绘图技术

#### 7\.2\.1 Hovmöller 图绘制

```matlab
% 关键参数设置
lat_range = [-10, 10];  % 热带地区纬度平均
time_range = [datetime(2023,1,1), datetime(2023,3,31)];
lon_range = [0, 180];   % 印度洋-西太平洋

% 数据准备
data_mean = squeeze(mean(data(:, lat_idx, :), 2));

% 绘图
contourf(lon, time, data_mean', [-5:0.5:5], 'LineStyle', 'none');
colormap(redblue(20));
caxis([-5, 5]);
```

#### 7\.2\.2 贡献分解图

```matlab
% Freddy生成区：南纬10-15°，东经80-90°
box_lon = [80, 90];
box_lat = [-15, -10];

% 区域平均
box_idx = find(lon >= box_lon(1) & lon <= box_lon(2) & ...
               lat >= box_lat(1) & lat <= box_lat(2));

% 计算各波动的相对贡献
total_var = var(original_data(box_idx, :));
mjo_var = var(MJO_data(box_idx, :));
mrg_var = var(MRG_data(box_idx, :));
er_var = var(ER_data(box_idx, :));
kelvin_var = var(Kelvin_data(box_idx, :));

contribution = [mjo_var, mrg_var, er_var, kelvin_var] / total_var * 100;
```

#### 7\.2\.3 3D 涡旋拉伸图

```matlab
% 经度-高度-时间三维图
[x, y, z] = meshgrid(lon, levels, time);
slice(x, y, z, vortex_stretching, [], [850, 700, 500, 200], []);
shading interp
alpha(0.7)
```

---

## 8\. 结果验证

### 8\.1 验证标准

|验证项|预期结果|容差范围|
|---|---|---|
|MJO 贡献占比|\~40%|±5%|
|Kelvin 波贡献|\~30%|±5%|
|ER 波贡献|\~15%|±3%|
|MRG 波贡献|\~15%|±3%|
|涡旋拉伸峰值时间|2023\-02\-05 ± 2 天|±3 天|

### 8\.2 验证方法

1. **视觉对比**：对比生成图片与论文图片的相似度

2. **数值检验**：计算区域平均的相关系数

3. **统计检验**：方差解释率的一致性检验

### 8\.3 常见偏差来源

1. 数据版本差异（ERA5 再分析数据更新）

2. 滤波参数细微差异

3. 气候态计算年份范围差异

---

## 9\. 常见问题与解决方案

### 9\.1 数据下载问题

**问题**：Earthdata 下载速度慢或中断

```bash
# 解决方案：使用aria2多线程下载
aria2c -x 8 -s 8 -c "下载链接"
```

**问题**：CDS API 请求被拒绝

- 确保接受了数据使用条款

- 检查 API 密钥是否正确配置

### 9\.2 环境配置问题

**问题**：Cartopy 安装失败

```bash
# 解决方案：使用conda安装
conda install -c conda-forge cartopy

# 或使用预编译包
pip install cartopy --only-binary :all:
```

**问题**：NCL 找不到共享库

```bash
# 设置环境变量
export NCARG_ROOT=/path/to/ncl
export PATH=$NCARG_ROOT/bin:$PATH
```

### 9\.3 代码运行问题

**问题**：MATLAB 内存不足

- 分批次处理数据

- 使用 single 精度代替 double

- 及时清理不需要的变量

**问题**：NetCDF 文件读写错误

- 确保文件路径不包含中文

- 检查文件是否完整下载

---

## 10\. 引用说明

### 10\.1 数据引用

```Plain Text
GPM数据:
Huffman, G.J., et al. (2019). GPM IMERG Final Precipitation L3 Half Hourly 0.1 degree x 0.1 degree V06.

ERA5数据:
Hersbach, H., et al. (2020). The ERA5 global reanalysis. Quarterly Journal of the Royal Meteorological Society.

OLR数据:
Liebmann, B. and C.A. Smith (1996). Description of a complete (interpolated) outgoing longwave radiation dataset.

IBTrACS数据:
Knapp, K.R., et al. (2010). International Best Track Archive for Climate Stewardship (IBTrACS).
```

### 10\.2 方法引用

```Plain Text
Wheeler-Kiladis滤波:
Wheeler, M. and G.N. Kiladis (1999). Convectively coupled equatorial waves: Analysis of clouds and temperature in the wavenumber-frequency domain.

热带波动理论:
Matsuno, T. (1966). Quasi-geostrophic motions in the equatorial area.
```

### 10\.3 本研究引用

如果您使用了本代码或数据，请引用：

```Plain Text
Chen, Y. (2025). The Role of Tropical Waves in the Genesis of Record-breaking Tropical Cyclone Freddy (2023).
Bachelor's Thesis, Nanjing University of Information Science & Technology.
```

---

**技术支持**：如有问题，请在 GitHub 仓库提交 Issue。

**许可证**：MIT License

> （注：文档部分内容可能由 AI 生成）
