# TC\-Freddy\-Tropical\-Waves 技术文档

**论文题目**：热带气旋“弗雷迪”（2023）生成过程中的热带波动作用分析
**作者**：陈勇
**版本**：v1\.0
**最后更新**：2026 年 5 月 11 日
**仓库地址**：[https://github\.com/CY18270852013/TC\-Freddy\-Tropical\-Waves](https://github.com/CY18270852013/TC-Freddy-Tropical-Waves)

---

## 目录

1. \[项目概述\]

    - 1\.1 研究背景与科学问题

    - 1\.2 研究内容与技术路线图

    - 1\.3 GitHub 仓库文件结构总览

    - 1\.4 复现预期结果说明

2. \[数据获取与准备\]

    - 2\.1 数据源详细信息

    - 2\.2 ERA5 再分析数据详细下载步骤

    - 2\.3 GPM IMERG 降水数据详细下载步骤

    - 2\.4 NOAA OLR 射出长波辐射数据下载

    - 2\.5 IBTrACS 台风最佳路径数据下载

    - 2\.6 推荐的数据目录结构

    - 2\.7 数据完整性检查方法

3. \[软件环境要求\]

    - 3\.1 MATLAB 版本要求与工具箱依赖

    - 3\.2 Python 版本要求与依赖库列表

    - 3\.3 NCL 环境配置

    - 3\.4 环境验证脚本与测试方法

    - 3\.5 硬件配置建议

4. \[数据预处理流程\]

    - 4\.1 预处理整体流程图

    - 4\.2 气候态计算与去除（傅里叶拟合方法）

    - 4\.3 异常场计算方法

    - 4\.4 VIMD（垂直积分水汽辐合）详细计算

    - 4\.5 涡旋拉伸项动力诊断计算

    - 4\.6 举例详解 MATLAB 预处理脚本

    - 4\.7 预处理结果验证方法

    - 4\.8 每个脚本数据处理情况

5. \[波数 \- 频率滤波（Wheeler\-Kiladis 方法）\]

    - 5\.1 Wheeler\-Kiladis 滤波方法概述

    - 5\.2 NCL 滤波环境配置

    - 5\.3 MJO 滤波：参数设置、物理意义、输入输出

    - 5\.4 Kelvin 波滤波：参数设置、物理意义、输入输出

    - 5\.5 ER 波（赤道罗斯贝波）滤波：参数设置、物理意义、输入输出

    - 5\.6 MRG 波（混合罗斯贝重力波）滤波：参数设置、物理意义、输入输出

    - 5\.7 滤波参数对照表

    - 5\.8 滤波结果质量评估方法

6. \[部分结果分析与绘图举例\]

    - 6\.1 论文图件举例说明

    - 6\.2 台风路径与强度演变图绘制

    - 6\.3 Hovmöller 时空演变图绘制

    - 6\.4 波动空间分布图绘制

    - 6\.5 时间序列与功率谱分析图绘制

    - 6\.6 波动贡献定量分析图绘制

    - 6\.7 每个绘图脚本详解

    - 6\.8 图形美化参数设置

7. \[Python 辅助脚本详解\]

    - 7\.1 Python 脚本索引表

    - 7\.2 数据下载类脚本详解

    - 7\.3 数据格式转换类脚本详解

    - 7\.4 统计分析类脚本详解

    - 7\.5 每个脚本的：输入文件、输出文件、执行命令、注意事项

8. \[完整代码运行顺序\]

    - 8\.1 整体运行流程图（Mermaid 流程图）

    - 8\.2 第一步：环境配置与验证

    - 8\.3 第二步：数据下载与完整性检查

    - 8\.4 第三步：数据预处理

    - 8\.5 第四步：波数 \- 频率滤波

    - 8\.6 第五步：结果分析与绘图

    - 8\.7 路径配置文件修改说明

    - 8\.8 内存管理与大文件处理建议

    - 8\.9 常见运行错误与解决方案

9. \[附录：关键方法原理\]

    - 9\.1 Wheeler\-Kiladis 波数 \- 频率滤波数学原理详细推导

    - 9\.2 傅里叶拟合气候态计算方法

    - 9\.3 涡度方程与涡旋拉伸项推导

    - 9\.4 VIMD 物理意义与计算公式推导

    - 9\.5 波动能量诊断方法

    - 9\.6 参考文献列表

    - 9\.7 常见问题 FAQ

---

## 1\. 项目概述

### 1\.1 研究背景与科学问题

热带气旋 Freddy（2023）是有记录以来持续时间最长、累积气旋能量（ACE）最高的热带气旋之一，在南印度洋经历了两次增强 \- 减弱 \- 再增强的过程，对马达加斯加、莫桑比克等国造成了严重影响。Freddy 以长达 36 天的生命史刷新全球记录，其极端性对热带气旋生成理论及预报提出了新的挑战。

本研究聚焦于\&\#34;弗雷迪\&\#34;的生成过程，系统探究了四种热带波动在其生成过程中的作用——热带季节内振荡（Madden\-Julian Oscillation，MJO）、混合罗斯贝重力波（Mixed Rossby\-Gravity，MRG）、赤道罗斯贝波（Equatorial Rossby，ER）和赤道Kelvin波（Equatorial Kelvin Waves）。

**核心科学问题**：

- 四种热带波动（MJO、Kelvin、ER、MRG）在 Freddy 生成过程中各自扮演了什么角色？

- 热带波动如何通过涡旋拉伸机制促进初始涡旋的发展？

- 不同尺度波动的协同作用如何影响热带气旋生成的时间和位置？

> **Freddy 生成区定义**：南印度洋 **10°S\-20°S, 110°E\-120°E**
> 
> **研究时间范围**：**2023 年 1 月 1 日 \- 2023 年 3 月 31 日**
> 
> **Freddy 生成时间**：**2023 年 2 月 6 日**
> 
> 

### 1\.2 研究内容与技术路线图

本研究采用**时空滤波**技术从观测数据中分离不同尺度的热带波动信号，结合**动力诊断**方法分析涡旋拉伸和对流激发机制。

```mermaid
graph TD
    A[原始数据获取] --> B[数据预处理]
    B --> C[气候态计算与去除]
    C --> D[异常场计算]
    D --> E[Wheeler-Kiladis波数-频率滤波]
    E --> F1[MJO信号提取]
    E --> F2[Kelvin波信号提取]
    E --> F3[ER波信号提取]
    E --> F4[MRG波信号提取]
    F1 & F2 & F3 & F4 --> G[动力诊断分析]
    G --> H[VIMD水汽辐合诊断]
    G --> I[涡旋拉伸项诊断]
    H & I --> J[结果可视化]
    J --> K[波动贡献定量评估]```

**主要技术路线**：

1. **数据预处理**：计算 15 年气候态，使用傅里叶拟合去除年循环，得到异常场

2. **波动分离**：使用 NCL 的`kf\_filter`函数进行 Wheeler\-Kiladis 波数 \- 频率滤波

3. **动力诊断**：计算 VIMD（垂直积分水汽辐合）和涡旋拉伸项

4. **统计分析**：量化各波动的相对贡献

5. **可视化**：生成 Hovmöller 图、空间分布图、时间序列图

### 1\.3 GitHub 仓库文件结构总览

```Plain Text
TC-Freddy-Tropical-Waves/
├── GPM_precipitation/              # GPM降水数据处理
│   ├── 6hourly/                    # 6小时分辨率处理
│   │   ├── GPM_6hourly_Cumulative_Precipitation.m
│   │   ├── calculate_GPM_anomaly_6hourly.m
│   │   ├── plot_precip_6hourly_freddy_box.m
│   │   ├── plot_precip_hovmuller_6hourly.m
│   │   └── *.ncl                   # 4种波动滤波脚本
│   └── daily/                      # 日分辨率处理
│       ├── calculate_GPM_precipitation_anomaly_daily.m
│       ├── plot_*_hovmoller_diagram.m
│       └── *.ncl                   # 4种波动滤波脚本
├── ERA5_uv/                        # ERA5风场数据处理
│   ├── 6hourly/
│   │   ├── calculate_uv_anomaly_6hourly.m
│   │   ├── plot_u_anomaly_6hourly_freddy_box.m
│   │   └── *.ncl
│   └── daily/
│       ├── transfer_uv_3hourly_to_daily.m
│       ├── calculate_ERA5_u_v_anomaly_daily.m
│       ├── plot_precip_uv_*.m      # 4种波动的降水+风场图
│       ├── plot_u_anomaly_daily_freddy_box.m
│       └── *.ncl
├── ERA5_VIMD/                      # 垂直积分水汽辐合
│   ├── calculate_VIMD_6hourly.m
│   ├── calculate_VIMD_anomaly_6hourly.m
│   ├── plot_vimd_freddy_box.m
│   └── *.ncl                       # 4种波动滤波脚本
├── ERA5_divergence/                # 散度与涡旋拉伸
│   ├── calculate_divergence_anomaly_6hourly.m
│   ├── plot_div_vortex_stretching_*.m  # 4种波动
│   ├── plot_vortex_stretching_3D_*.m   # 4种波动3D图
│   └── *.ncl
├── ERA5_relative_humidity/         # 相对湿度分析
│   └── plot_q_freddy_box.m
├── OLR/                            # 射出长波辐射
│   ├── calculate_OLR_anomaly_daily.m
│   ├── plot_olr_freddy_box.m
│   └── plot_olr_*.m                # 4种波动
├── Python_codes/                   # Python辅助脚本
│   ├── Freddy_&_Dingani_Tracks_(2023).py
│   ├── Monthly_Mean_Vertical_Wind_Shear.py
│   ├── mean_specific_humidity_at_850 _Pa.py
│   ├── sst_with_full_track.py
│   └── wind_and_precipitation.py
├── LICENSE
├── README.md
└── TC-Freddy-Tropical-Waves 技术文档.pdf           # 本文档
```

### 1\.4 复现预期结果说明

成功复现本研究应获得以下结果：

|验证项|预期结果|容差范围|
|---|---|---|
|MJO 贡献占比|\~40%|±5%|
|Kelvin 波贡献|\~30%|±5%|
|ER 波贡献|\~15%|±3%|
|MRG 波贡献|\~15%|±3%|
|涡旋拉伸峰值时间|2023\-02\-05 ± 2 天|±3 天|
|VIMD 辐合峰值|2023\-02\-04 ± 1 天|±2 天|

> 💡 **验证方法**：对比生成的 Hovmöller 图中波动传播方向和速度，检查时间序列的峰值是否与 Freddy 生成时间对应。
> 
> 

---

## 2\. 数据获取与准备

### 2\.1 数据源详细信息

#### 2\.1\.1 ERA5再分析数据

- 来源：ECMWF Climate Data Store \(CDS\)（[https://cds\.climate\.copernicus\.eu](https://cds.climate.copernicus.eu/)）

- 时间范围：2009年1月1日至2023年12月31日

- 空间范围：10°N\~30°S, 0°\~360°E

- 空间分辨率：0\.5°×0\.5°

- 时间分辨率：6小时（00:00, 06:00, 12:00, 18:00 UTC）

- 所需变量：

    - u（东西风分量）、v（南北风分量）

    - q（比湿）、r（相对湿度）

    - d（散度）、vo（相对涡度）

    - 气压层：1000, 975, 950, 925, 900, 875, 850, 825, 800, 775, 750, 700, 650, 600, 550, 500, 450, 400, 350, 300, 250, 225, 200, 175, 150, 125, 100 hPa（共27层）

- 文件命名：`YYYYMM\_uv\.nc`, `YYYYMM\_q\.nc`, `YYYYMM\_dv\.nc`

#### 2\.1\.2 GPM IMERG降水数据

- 来源：NASA GES DISC（[https://disc\.gsfc\.nasa\.gov/datasets/GPM\_3IMERGHH\_07/](https://disc.gsfc.nasa.gov/datasets/GPM_3IMERGHH_07/)）

- 产品：GPM IMERG Final Run V07

- 时间范围：2009年1月1日至2023年12月31日

- 空间范围：90°S\~90°N, 180°W\~180°E

- 空间分辨率：0\.1°×0\.1°

- 时间分辨率：30分钟（原始）、6小时累积和日累积（处理后）

- 变量：precipitation（降水率，单位mm/hr）

- 文件格式：HDF5（原始）、NetCDF（处理后）

#### 2\.1\.3 NOAA OLR数据

- 来源：NOAA NCEI（[https://www\.ncei\.noaa\.gov/products/climate\-data\-records/outgoing\-longwave\-radiation\-daily](https://www.ncei.noaa.gov/products/climate-data-records/outgoing-longwave-radiation-daily)）

- 产品：OLR\-Daily CDR（Climate Data Record）Ver01Rev02

- 时间范围：2009年1月1日至2023年12月31日

- 空间范围：90°S\~90°N, 0°\~360°E

- 空间分辨率：1\.0°×1\.0°

- 时间分辨率：日平均

- 变量：olr（向外长波辐射通量，单位W/m²）

- 文件格式：NetCDF（每年一个文件）

#### 2\.1\.4 IBTrACS最佳路径数据

- 来源：NOAA NCEI（[https://www\.ncei\.noaa\.gov/products/international\-best\-track\-archive](https://www.ncei.noaa.gov/products/international-best-track-archive)）

- 版本：v04r01

- 用途：获取热带气旋\&\#34;弗雷迪\&\#34;（SID: 2023036S12117）的路径和强度信息

### 2\.2 ERA5 再分析数据详细下载步骤

**官方网站**：[https://cds\.climate\.copernicus\.eu/](https://cds.climate.copernicus.eu/)

**前置要求**：

- 注册 CDS 账号

- 安装`cdsapi` Python 库

- 配置`\~/\.cdsapirc`文件

#### 安装 CDS API

```bash
pip install cdsapi

# 配置API密钥
echo "url: https://cds.climate.copernicus.eu/api/v2
key: YOUR_UID:YOUR_API_KEY" > ~/.cdsapirc
```

#### 下载脚本：u/v 风场数据

```python
import cdsapi

c = cdsapi.Client()

# 下载850hPa和200hPa的u/v风场数据
c.retrieve(
    'reanalysis-era5-pressure-levels',
    {
        'product_type': 'reanalysis',
        'variable': ['u_component_of_wind', 'v_component_of_wind'],
        'pressure_level': ['850', '200'],
        'year': ['2009', '2010', '2011', '2012', '2013', '2014', '2015',
                 '2016', '2017', '2018', '2019', '2020', '2021', '2022', '2023'],
        'month': ['01', '02', '03', '04', '05', '06',
                  '07', '08', '09', '10', '11', '12'],
        'day': [f'{i:02d}' for i in range(1, 32)],
        'time': ['00:00', '06:00', '12:00', '18:00'],
        'area': ['10', '0', '-30', '360'],  # N, W, S, E
        'format': 'netcdf',
    },
    'ERA5_uv_2009-2023.nc'
)
```

#### 下载脚本：比湿、散度、涡度数据

```python
import cdsapi

c = cdsapi.Client()

# 下载所有气压层的比湿、散度、相对涡度
pressure_levels = ['1000', '975', '950', '925', '900', '875', '850', '825', '800',
                   '775', '750', '700', '650', '600', '550', '500', '450', '400',
                   '350', '300', '250', '225', '200', '175', '150', '125', '100']

c.retrieve(
    'reanalysis-era5-pressure-levels',
    {
        'product_type': 'reanalysis',
        'variable': ['specific_humidity', 'divergence', 'vorticity', 'relative_humidity'],
        'pressure_level': pressure_levels,
        'year': ['2023'],
        'month': ['01', '02', '03'],
        'day': [f'{i:02d}' for i in range(1, 32)],
        'time': ['00:00', '06:00', '12:00', '18:00'],
        'area': ['10', '0', '-30', '360'],
        'format': 'netcdf',
    },
    'ERA5_q_dv_vo_2023.nc'
)
```

> ⏱️ **预计耗时**：ERA5 数据下载约需 **2\-3 小时**，取决于网络速度。建议分月份下载以避免请求超时。
> 
> 

### 2\.3 GPM IMERG 降水数据详细下载步骤

**官方网站**：[https://disc\.gsfc\.nasa\.gov/datasets/GPM\_3IMERGHH\_07/](https://disc.gsfc.nasa.gov/datasets/GPM_3IMERGHH_07/)

**前置要求**：

- 注册 NASA Earthdata 账号

- 配置`\.netrc`文件进行身份验证

#### 下载方法 1：使用 wget 批量下载

```bash
# 配置Earthdata身份验证
echo "machine urs.earthdata.nasa.gov login YOUR_USERNAME password YOUR_PASSWORD" > ~/.netrc
chmod 0600 ~/.netrc

# 批量下载2023年1-3月的数据
for year in 2023; do
    for month in 01 02 03; do
        for day in $(seq -w 1 31); do
            doy=$(date -d "$year-$month-$day" +%j 2>/dev/null)
            if [ $? -eq 0 ]; then
                wget --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies \
                     --keep-session-cookies --no-check-certificate --auth-no-challenge=on \
                     -r -np -nd -A "*.HDF5" \
                     "https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGHH.07/$year/$doy/"
            fi
        done
    done
done
```

#### 下载方法 2：使用 Python 脚本下载

```python
import requests
from datetime import datetime, timedelta
import os

# Earthdata认证
session = requests.Session()
session.auth = ('YOUR_USERNAME', 'YOUR_PASSWORD')

base_url = "https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGHH.07"
output_dir = "./data/GPM/30min/"
os.makedirs(output_dir, exist_ok=True)

# 下载2023年1-3月
start_date = datetime(2023, 1, 1)
end_date = datetime(2023, 3, 31)

current_date = start_date
while current_date <= end_date:
    year = current_date.year
    doy = current_date.timetuple().tm_yday
    url = f"{base_url}/{year}/{doy:03d}/"
    
    print(f"下载: {year}-{current_date.month:02d}-{current_date.day:02d} (DOY: {doy})")
    
    # 此处添加具体文件下载逻辑
    current_date += timedelta(days=1)
```

> ⚠️ **注意**：GPM IMERG 数据量很大，2023 年 1\-3 月约有 **4320 个 HDF5 文件**，总计约 **50GB**。建议使用多线程下载工具如`aria2`加速。
> 
> 



### 2\.4 NOAA OLR 射出长波辐射数据下载

**官方网站**：[https://www\.esrl\.noaa\.gov/psd/](https://www.esrl.noaa.gov/psd/)

```bash
# 方法1：直接下载日平均OLR数据（推荐）
wget ftp://ftp.cdc.noaa.gov/Datasets/interp_OLR/olr.day.mean.nc

# 方法2：分年度下载
for year in {2009..2023}; do
    wget "https://downloads.psl.noaa.gov/Datasets/interp_OLR/olr-daily_v01r02_${year}0101_${year}1231.nc"
done
```

### 2\.5 IBTrACS 台风最佳路径数据下载

**官方网站**：[https://www\.ncei\.noaa\.gov/products/international\-best\-track\-archive](https://www.ncei.noaa.gov/products/international-best-track-archive)

```bash
# 南印度洋区域数据
wget "https://www.ncei.noaa.gov/data/international-best-track-archive-for-climate-stewardship-ibtracs/v04r01/access/netcdf/IBTrACS.SI.v04r01.nc"

# 或下载全球数据
wget "https://www.ncei.noaa.gov/data/international-best-track-archive-for-climate-stewardship-ibtracs/v04r01/access/netcdf/IBTrACS.ALL.v04r01.nc"
```

### 2\.6 推荐的数据目录结构

```Plain Text
data/
├── GPM/
│   ├── 30min/              # 原始30分钟HDF5文件
│   │   └── 3B-HHR.MS.MRG.3IMERG.*.HDF5
│   ├── 6hourly/            # 处理后的6小时累积
│   │   └── GPM_6hourly_*.nc
│   └── daily/              # 日累积数据文件
│       └── GPM_daily_*.nc
├── ERA5/
│   ├── uv/                 # u/v风场数据
│   │   ├── 200901_uv.nc
│   │   ├── 200902_uv.nc
│   │   └── ...
│   ├── q/                  # 比湿数据
│   │   ├── 200901_q.nc
│   │   └── ...
│   ├── dv/                 # 散度数据
│   │   ├── 200901_dv.nc
│   │   └── ...
│   └── VIMD/               # VIMD计算结果
│       ├── 200901_VIMD.nc
│       └── ...
├── OLR/
│   ├── olr-daily_v01r02_20090101_20091231.nc
│   ├── olr-daily_v01r02_20100101_20101231.nc
│   └── ...
└── IBTrACS/
    └── IBTrACS.SI.v04r01.nc
```

### 2\.7 数据完整性检查方法

#### 检查脚本示例

```matlab
% GPM数据完整性检查
data_dir = './data/GPM/30min/';
start_date = datetime(2023,1,1);
end_date = datetime(2023,3,31);
expected_files = 0;
actual_files = 0;

current_date = start_date;
while current_date <= end_date
    % 每天应有48个30分钟文件
    expected_files = expected_files + 48;
    
    % 检查实际文件数量
    files = dir(fullfile(data_dir, ['*', datestr(current_date, 'yyyymmdd'), '*.HDF5']));
    actual_files = actual_files + length(files);
    
    current_date = current_date + days(1);
end

fprintf('GPM数据完整性检查:\n');
fprintf('  预期文件数: %d\n', expected_files);
fprintf('  实际文件数: %d\n', actual_files);
fprintf('  完整度: %.2f%%\n', 100*actual_files/expected_files);

if actual_files < expected_files
    warning('GPM数据不完整，缺少 %d 个文件!', expected_files - actual_files);
end
```

> 💡 **实用技巧**：使用`ncdump \-h filename\.nc`快速检查 NetCDF 文件的维度和变量信息，确保数据格式正确。
> 
> 

---

## 3\. 软件环境要求

### 3\.1 MATLAB 版本要求与工具箱依赖

|软件|版本要求|用途|
|---|---|---|
|MATLAB|R2020a 或更高|数据预处理、异常值计算、结果分析、绘图|

**必需工具箱**：

- **Parallel Computing Toolbox**（可选，用于加速 FFT 计算）

- **Mapping Toolbox**（可选，用于地图绘制）

- **Statistics and Machine Learning Toolbox**（用于统计分析）

**验证 MATLAB 环境**：

```matlab
% 检查MATLAB版本
fprintf('MATLAB版本: %s\n', version);

% 检查工具箱
required_toolboxes = {'Parallel Computing Toolbox', 'Mapping Toolbox'};
for i = 1:length(required_toolboxes)
    if license('test', required_toolboxes{i})
        fprintf('✓ %s: 已安装\n', required_toolboxes{i});
    else
        fprintf('⚠ %s: 未安装（可选）\n', required_toolboxes{i});
    end
end
```

### 3\.2 Python 版本要求与依赖库列表

|软件|版本要求|用途|
|---|---|---|
|Python|3\.8\+|数据下载、背景分析图绘制|

**完整依赖库列表**：

|库名|版本要求|用途|
|---|---|---|
|numpy|\&gt;=1\.21\.0|数值计算|
|pandas|\&gt;=1\.3\.0|数据处理|
|xarray|\&gt;=0\.19\.0|NetCDF 数据处理|
|netCDF4|\&gt;=1\.5\.7|NetCDF 文件读写|
|scipy|\&gt;=1\.7\.0|科学计算、FFT|
|cartopy|\&gt;=0\.20\.0|地图投影|
|matplotlib|\&gt;=3\.4\.0|数据可视化|
|metpy|\&gt;=1\.2\.0|气象计算|
|cdsapi|\&gt;=0\.5\.1|ERA5 数据下载|
|tqdm|\&gt;=4\.62\.0|进度条显示|

#### 环境安装命令

```bash
# 使用conda安装（推荐）
conda create -n tc-freddy python=3.9
conda activate tc-freddy

# 安装核心依赖
conda install -c conda-forge numpy pandas xarray netCDF4 scipy
conda install -c conda-forge cartopy matplotlib metpy
conda install -c conda-forge cdsapi tqdm

# 验证安装
python -c "import numpy, pandas, xarray, cartopy, matplotlib; print('所有依赖库安装成功!')"
```

### 3\.3 NCL 环境配置（用于波数 \- 频率滤波）

|软件|版本要求|用途|
|---|---|---|
|NCL|6\.6\.2 或更高|Wheeler\-Kiladis 波数 \- 频率滤波|

#### NCL 安装方法

```bash
# 方法1：使用conda安装（推荐）
conda install -c conda-forge ncl

# 方法2：从源码安装
# 参考：https://www.ncl.ucar.edu/Download/

# 验证安装
ncl -V
```

#### 必需的 NCL contributed 脚本

```ncl
; 在所有NCL脚本开头添加以下加载语句
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/kf_filter.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"
```

> ⚠️ **重要**：`kf\_filter\.ncl`是 Wheeler\-Kiladis 滤波的核心函数，必须确保该文件在 NCL 的搜索路径中。
> 
> 

### 3\.4 环境验证脚本与测试方法

创建环境验证脚本 `test\_environment\.ncl`：

```ncl
begin
    print("=== NCL环境验证 ===")
    
    ; 检查kf_filter函数是否可用
    if (isdefined("kf_filter")) then
        print("✓ kf_filter函数: 可用")
    else
        print("✗ kf_filter函数: 不可用")
        print("  请检查kf_filter.ncl是否正确加载")
    end if
    
    ; 测试简单的滤波操作
    test_data = random_uniform(-1, 1, (/100, 360/))
    obsPerDay = 1
    tMin = 10
    tMax = 30
    kMin = 1
    kMax = 5
    hMin = 8
    hMax = 90
    waveName = "Kelvin"
    
    result = kf_filter(test_data, obsPerDay, tMin, tMax, kMin, kMax, hMin, hMax, waveName)
    
    if (all(ismissing(result))) then
        print("✗ 滤波测试: 失败")
    else
        print("✓ 滤波测试: 成功")
    end if
    
    print("=== 环境验证完成 ===")
end
```

运行验证：

```bash
ncl test_environment.ncl
```

### 3\.5 硬件配置建议

|组件|最低配置|推荐配置|说明|
|---|---|---|---|
|**CPU**|4 核心|8 核心以上|并行计算加速 FFT 和滤波|
|**内存**|16GB|32GB 以上|处理大尺度气象数据|
|**存储**|100GB SSD|500GB SSD|存储原始数据和中间结果|
|**网络**|10Mbps|100Mbps 以上|快速下载气象数据|

> 💡 **内存优化建议**：处理 15 年的 6 小时数据时，建议使用 **32GB 以上内存**。如内存不足，可分年度处理数据。
> 
> 

---

## 4\. 数据预处理流程

### 4\.1 预处理整体流程图

```mermaid
graph TD
    A[原始数据] --> B[时间聚合]
    B --> C[30min→6hourly]
    B --> D[3hourly→daily]
    C --> E[气候态计算]
    D --> E
    E --> F[15年日循环平均]
    F --> G[傅里叶拟合平滑]
    G --> H[保留前3阶谐波]
    H --> I[异常场计算]
    I --> J[原始场 - 拟合气候态]
    J --> K[标准化处理]
    K --> L[VIMD计算]
    K --> M[散度计算]
    L --> N[VIMD异常场]
    M --> O[散度异常场]```

### 4\.2 气候态计算与去除（傅里叶拟合方法）

**数学原理**：

对于长度为 N（N=365 或 1460）的年循环时间序列 x \(t\)，其傅里叶级数展开为：

$x(t) = a_0 + \sum_{k=1}^{N/2} [a_k \cos(2\pi k t/N) + b_k \sin(2\pi k t/N)]$

**前三阶谐波滤波保留**：

- k=0（直流分量，年平均）

- k=1（一阶谐波，周期 1 年）

- k=2（二阶谐波，周期半年）

- k=3（三阶谐波，周期 4 个月）

**MATLAB 实现**：

```matlab
function fit_climatology = fourier_fit(climatology, num_harmonics)
    % 傅里叶拟合气候态
    % 输入: climatology - 原始气候态 (365, nlon, nlat)
    %       num_harmonics - 保留的谐波数量
    % 输出: fit_climatology - 拟合后的气候态
    
    [n_days, nlon, nlat] = size(climatology);
    fit_climatology = zeros(size(climatology));
    
    for i = 1:nlon
        for j = 1:nlat
            % 提取单个格点的时间序列
            ts = squeeze(climatology(:, i, j));
            
            % FFT变换
            ts_fft = fft(ts);
            
            % 保留前num_harmonics+1个系数（直流+基频+...）
            ts_fft(num_harmonics+2:end-num_harmonics) = 0;
            
            % 逆FFT
            ts_fit = ifft(ts_fft);
            
            fit_climatology(:, i, j) = real(ts_fit);
        end
    end
end
```

> 💡 **物理意义**：傅里叶拟合避免了简单日气候平均值导致的年内变化细节丢失，能更准确地刻画温度、降水等的季节变化。
> 
> 

### 4\.3 异常场计算方法

**完整计算步骤**：

```matlab
% 步骤1：读取所有数据
all_data = read_all_gpm_6hourly();

% 步骤2：计算日循环气候态（每年同一天的平均值）
climatology = zeros(366, lon_size, lat_size);
for day = 1:366
    indices = get_day_of_year_indices(all_data.time, day);
    climatology(day,:,:) = mean(all_data.precip(:,:,indices), 3);
end

% 步骤3：傅里叶拟合（保留前5个谐波）
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

> ⏱️ **预计耗时**：GPM 6 小时异常场计算约需 **4\-6 小时**，取决于 CPU 性能。
> 
> 

### 4\.4 VIMD（垂直积分水汽辐合）详细计算

**VIMD 数学定义**：

$\text{VIMD} = -\frac{1}{g} \int_{1000}^{100} \nabla \cdot (q\mathbf{V}) dp$

其中：

- $g = 9.8 , \text{m/s}^2$ 为重力加速度

- $q$ = 比湿

- $\mathbf{V} = (u, v)$ = 风矢量

- $\nabla \cdot$ = 水平散度算子

- $dp$ = 气压层厚度

**球坐标系下的散度展开**：

$\nabla \cdot (q\mathbf{V}) = \frac{1}{a\cos\varphi}\left[ \frac{\partial(qu)}{\partial\lambda} + \frac{\partial(qv\cos\varphi)}{\partial\varphi} \right]$

其中$a$为地球半径，$\varphi$为纬度，$\lambda$为经度。

**MATLAB 核心实现**：

```matlab
% 预计算常数
g = 9.8;           % 重力加速度 (m/s^2)
a = 6371000;       % 地球半径 (m)
p_Pa = plev * 100; % hPa转换为Pa

% 垂直积分权重（梯形积分法）
w = zeros(nlev, 1);
w(1) = (p_Pa(1) - p_Pa(2)) / 2;
for k = 2:nlev-1
    w(k) = (p_Pa(k-1) - p_Pa(k+1)) / 2;
end
w(nlev) = (p_Pa(nlev-1) - p_Pa(nlev)) / 2;

% 预计算纬度余弦
lat_rad = deg2rad(lat);
cos_lat_2d = repmat(cos(lat_rad)', nlon, 1);
inv_a_coslat = 1 ./ (a * cos_lat_2d);

% 差分索引（循环边界条件）
i_west = [nlon, 1:nlon-1];
i_east = [2:nlon, 1];

% 逐层计算
for k = 1:nlev
    % 水汽通量
    qu = q_k .* u_k;
    qv = q_k .* v_k;
    qv_cos = qv .* cos_lat_2d;
    
    % 经度导数 ∂(qu)/∂λ
    dqu_dlambda = (qu(i_east, :) - qu(i_west, :)) / (2 * dlambda);
    
    % 纬度导数 ∂(qv cosφ)/∂φ
    dqvcos_dphi = (qv_cos(:, i_south) - qv_cos(:, i_north)) / (2 * dphi);
    
    % 水平散度
    div_qV = (dqu_dlambda + dqvcos_dphi) .* inv_a_coslat;
    
    % 垂直积分累加
    vimd_t = vimd_t + div_qV * w(k);
end

% 乘以-1/g得到VIMD
vimd_t = -1/g * vimd_t;
```

**物理意义**：

- **VIMD \&gt; 0**：整层水汽辐合，有利于对流发展和降水

- **VIMD \&lt; 0**：整层水汽辐散，不利于对流发展

> ⏱️ **预计耗时**：VIMD 计算约需 **8\-12 小时**（15 年数据），建议分月份处理。
> 
> 

### 4\.5 涡旋拉伸项动力诊断计算

**涡旋拉伸项定义**：

$S = \eta \cdot (-\nabla \cdot \mathbf{V}')$

其中：

- $\eta = \zeta + f$（绝对涡度）

- $\zeta$：相对涡度（从 ERA5 变量`vo`直接获取）

- $f = 2\Omega \sin\varphi$（行星涡度）

- $\mathbf{V}'$：滤波后的风场异常

- 负号确保低层辐合（$\nabla \cdot \mathbf{V}' < 0$）产生正贡献

**MATLAB 核心实现**：

```matlab
% 科氏参数
Omega = 7.2921e-5;  % 地球自转角速度 (rad/s)
f_array = 2 * Omega * sin(deg2rad(lat));

% 计算绝对涡度: η = ζ + f
abs_vorticity = vo_box + repmat(reshape(f_array, [1, lat_size, 1]), [lon_size, 1, time_size]);

% 计算涡旋拉伸项: η × (-∇·V')
vortex_stretching = abs_vort_mean .* (-mjo_div_mean);
```

**物理意义**：
涡旋拉伸项来源于涡度方程的垂直拉伸项：
$\frac{D\zeta}{Dt} \propto \eta \frac{\partial w}{\partial z}$

在低层大气中，根据连续性方程，辐合（$\nabla \cdot \mathbf{V}' < 0$）意味着上升运动（$\partial w/\partial z > 0$），从而拉伸绝对涡度管、增强气旋性环流。



### 4\.6 举例详解 MATLAB 预处理脚本

#### GPM\_6hourly\_Cumulative\_Precipitation\.m

|项目|内容|
|---|---|
|**输入文件**|GPM IMERG 30 分钟 HDF5 文件|
|**输出文件**|`GPM\_6hourly\_YYYYMMDDHHMMSS\_YYYYMMDDHHMMSS\.nc`|
|**关键参数**|时间窗口：6 小时|
|**核心逻辑**|12 个 30 分钟文件累加，降水率 ×0\.5 小时转换为累积量|
|**预计耗时**|2\-3 小时|

**代码片段**：

```matlab
precip_6h = zeros(lon_size, lat_size);
for f = 1:length(files)
    data = read_gpm_file(files{f});
    precip_6h = precip_6h + data.precipitation * 0.5;  % mm/h × h = mm
end
```

#### calculate\_GPM\_anomaly\_6hourly\.m

|项目|内容|
|---|---|
|**输入文件**|GPM\_*6hourly\_*\*\.nc（2009\-2023 年）|
|**输出文件**|`GPM\_anomaly\_6hourly\_20220901\_20230630\.nc`|
|**关键参数**|傅里叶谐波数：5，纬度范围：20°S\-20°N|
|**核心逻辑**|15 年气候态计算→傅里叶拟合→异常场计算|
|**预计耗时**|4\-6 小时|

#### calculate\_VIMD\_6hourly\.m

|项目|内容|
|---|---|
|**输入文件**|ERA5 u/v/q 数据（27 个气压层）|
|**输出文件**|`YYYYMM\_VIMD\.nc`（共 180 个文件）|
|**关键参数**|积分范围：1000\-100 hPa|
|**核心逻辑**|逐层计算水汽通量散度→梯形法垂直积分|
|**预计耗时**|8\-12 小时|

### 4\.7 预处理结果验证方法

**验证步骤**：

```matlab
% 1. 检查异常场统计特性
fprintf('异常场统计:\n');
fprintf('  均值: %.4e (应接近0)\n', mean(anomaly(:), 'omitnan'));
fprintf('  标准差: %.4f\n', std(anomaly(:), 'omitnan'));
fprintf('  最小值: %.4f\n', min(anomaly(:), [], 'omitnan'));
fprintf('  最大值: %.4f\n', max(anomaly(:), [], 'omitnan'));

% 2. 检查空间相关性
corr_map = corr(squeeze(anomaly(1, :, :))');
fprintf('  空间平均相关系数: %.4f\n', mean(corr_map(:), 'omitnan'));

% 3. 可视化检查
figure;
subplot(1,2,1);
pcolor(lon, lat, squeeze(mean(climatology, 1))');
shading interp;
colorbar;
title('原始气候态');

subplot(1,2,2);
pcolor(lon, lat, squeeze(mean(fit_climatology, 1))');
shading interp;
colorbar;
title('傅里叶拟合后气候态');
```

> ⚠️ **常见问题**：如果异常场均值显著偏离 0，说明气候态计算有误，需检查日循环计算是否正确。
> 
> 

### 4\.8 每个脚本数据处理情况

1. calculate\_GPM\_precipitation\_anomaly\_daily\.m

    - 输入数据：`\\\\DS1821\\Observation\\GPM\\daily`（2009\.01\.01–2023\.12\.31 日降水数据）

    - 输出数据：`GPM\_anomaly\_daily\_20220101\_20231231\_30S\_30N\.nc`
    附：`anomaly\_data\_30S\_30N\.mat`、`climatology\_30S\_30N\.mat`、`fit\_climatology\_30S\_30N\.mat`、`mean\_precip\_30S\_30N\.mat`、`normalized\_precip\_30S\_30N\.mat`、`original\_daily\_precipitation\_30S\_30N\.mat`

2. GPM\_anomaly\_daily\_for\_ER\_20220901\_20230630\.ncl

    - 输入数据：`GPM\_anomaly\_daily\_20220101\_20231231\_30S\_30N\.nc`

    - 输出数据：`GPM\_anomaly\_for\_ER\_daily\_20220901\_20230630\.nc`

3. GPM\_anomaly\_daily\_for\_Kelvin\_20220901\_20230630\.ncl

    - 输入数据：`GPM\_anomaly\_daily\_20220101\_20231231\_30S\_30N\.nc`

    - 输出数据：`GPM\_anomaly\_for\_Kelvin\_daily\_20220901\_20230630\.nc`

4. GPM\_anomaly\_daily\_for\_MJO\_20220901\_20230630\.ncl

    - 输入数据：`GPM\_anomaly\_daily\_20220101\_20231231\_30S\_30N\.nc`

    - 输出数据：`GPM\_anomaly\_for\_MJO\_daily\_20220901\_20230630\.nc`

5. GPM\_anomaly\_daily\_for\_MRG\_20220901\_20230630\.ncl

    - 输入数据：`GPM\_anomaly\_daily\_20220101\_20231231\_30S\_30N\.nc`

    - 输出数据：`GPM\_anomaly\_for\_MRG\_daily\_20220901\_20230630\.nc`

6. plot\_mrg\_hovmoller\_diagram\.m

    - 输入数据：`GPM\_anomaly\_for\_MRG\_daily\_20220901\_20230630\.nc`

    - 输出图片：`mrg\_hovmoller\_diagram\_10S\_10N\.png`

7. plot\_mjo\_hovmoller\_diagram\.m

    - 输入数据：`GPM\_anomaly\_for\_MJO\_daily\_20220901\_20230630\.nc`

    - 输出图片：`mjo\_hovmoller\_diagram\_10S\_10N\.png`

8. plot\_kelvin\_hovmoller\_diagram\.m

    - 输入数据：`GPM\_anomaly\_for\_Kelvin\_daily\_20220901\_20230630\.nc`

    - 输出图片：`kelvin\_hovmoller\_diagram\_10S\_10N\.png`

9. plot\_er\_hovmoller\_diagram\.m

    - 输入数据：`GPM\_anomaly\_for\_ER\_daily\_20220901\_20230630\.nc`

    - 输出图片：`er\_hovmoller\_diagram\_10S\_10N\_improved\.png`

10. transfer\_uv\_3hourly\_to\_daily\.m

    - 输入数据：`F:\\ERA5\_u\_v\_w\_3hourly`（2009\.01\.01–2023\.12\.31 每3小时风场数据）

    - 输出数据：`u\_v\_daily\_20090101\_20231231\.nc`

11. calculate\_ERA5\_u\_v\_anomaly\_daily\.m

    - 输入数据：`u\_v\_daily\_20090101\_20231231\.nc`

    - 输出数据：`u\_v\_anomaly\_daily\_20220101\_20231231\.nc`，附：`normalized\_u\_v\_30N\_30S\.mat`、`original\_u\_v\_daily\_30N\_30S\.mat`、`u\_v\_anomaly\_30N\_30S\.mat`、`u\_v\_climatology\_30N\_30S\.mat`、`u\_v\_fit\_climatology\_30N\_30S\.mat`、`u\_v\_mean\_30N\_30S\.mat`

12. u\_v\_anomaly\_for\_ER\_daily\_20220101\_20231231\.ncl

    - 输入数据：`u\_v\_anomaly\_daily\_20220101\_20231231\.nc`

    - 输出数据：`u\_v\_anomaly\_for\_ER\_daily\_20220101\_20231231\.nc`

13. u\_v\_anomaly\_for\_Kelvin\_daily\_20220101\_20231231\.ncl

    - 输入数据：`u\_v\_anomaly\_daily\_20220101\_20231231\.nc`

    - 输出数据：`u\_v\_anomaly\_for\_Kelvin\_daily\_20220101\_20231231\.nc`

14. u\_v\_anomaly\_for\_MJO\_daily\_20220101\_20231231\.ncl

    - 输入数据：`u\_v\_anomaly\_daily\_20220101\_20231231\.nc`

    - 输出数据：`u\_v\_anomaly\_for\_MJO\_daily\_20220101\_20231231\.nc`

15. u\_v\_anomaly\_for\_MRG\_daily\_20220101\_20231231\.ncl

    - 输入数据：`u\_v\_anomaly\_daily\_20220101\_20231231\.nc`

    - 输出数据：`u\_v\_anomaly\_for\_MRG\_daily\_20220101\_20231231\.nc`

16. plot\_precip\_uv\_er\.m

    - 输入数据：`u\_v\_anomaly\_for\_ER\_daily\_20220101\_20231231\.nc`、`GPM\_anomaly\_for\_ER\_daily\_20220901\_20230630\.nc`

    - 输出图片：`ER\_precip\_wind\_anomalies\_20230201\.png` … `ER\_precip\_wind\_anomalies\_20230210\.png`（10张）

17. plot\_precip\_uv\_kelvin\.m

    - 输入数据：`u\_v\_anomaly\_for\_Kelvin\_daily\_20220101\_20231231\.nc`、`GPM\_anomaly\_for\_Kelvin\_daily\_20220901\_20230630\.nc`

    - 输出图片：`Kelvin\_precip\_wind\_anomalies\_20230201\.png` … `Kelvin\_precip\_wind\_anomalies\_20230210\.png`（10张）

18. plot\_precip\_uv\_mjo\.m

    - 输入数据：`u\_v\_anomaly\_for\_MJO\_daily\_20220101\_20231231\.nc`、`GPM\_anomaly\_for\_MJO\_daily\_20220901\_20230630\.nc`

    - 输出图片：`MJO\_precip\_wind\_anomalies\_20230201\.png` … `MJO\_precip\_wind\_anomalies\_20230210\.png`（10张）

19. plot\_precip\_uv\_mrg\.m

    - 输入数据：`u\_v\_anomaly\_for\_MRG\_daily\_20220101\_20231231\.nc`、`GPM\_anomaly\_for\_MRG\_daily\_20220901\_20230630\.nc`

    - 输出图片：`MRG\_precip\_wind\_anomalies\_20230201\.png` … `MRG\_precip\_wind\_anomalies\_20230210\.png`（10张）

20. plot\_u\_anomaly\_daily\_freddy\_box\.m

    - 输入数据：`u\_v\_anomaly\_daily\_20220101\_20231231\.nc`、`u\_v\_anomaly\_for\_ER\_daily\_20220101\_20231231\.nc`、`u\_v\_anomaly\_for\_Kelvin\_daily\_20220101\_20231231\.nc`、`u\_v\_anomaly\_for\_MJO\_daily\_20220101\_20231231\.nc`、`u\_v\_anomaly\_for\_MRG\_daily\_20220101\_20231231\.nc`

    - 输出图片：`Freddy\_Genesis\_U\_Wind\_Anomaly\_Contributions\.png`、`U\_Wind\_Contributions\_Subplots\.png`

21. GPM\_6hourly\_Cumulative\_Precipitation\.m

    - 输入数据：`\\\\DS1821\\Observation\\GPM`（2009–2023 半小时降水数据）

    - 输出数据：`GPM\_6hourly\_20090101000000\_20090101055959\.nc` … `GPM\_6hourly\_20231231180000\_20231231235959\.nc`（全部6小时累积文件）

22. calculate\_GPM\_anomaly\_6hourly\.m

    - 输入数据：`GPM\_6hourly\_20090101\_20231231`（全部6小时累积文件）

    - 输出数据：`GPM\_anomaly\_6hourly\_20220901\_20230630\.nc`

23. GPM\_anomaly\_6hourly\_for\_ER\_20220901\_20230630\.ncl

    - 输入数据：`GPM\_anomaly\_6hourly\_20220901\_20230630\.nc`

    - 输出数据：`GPM\_anomaly\_6hourly\_for\_ER\_20220901\_20230630\.nc`

24. GPM\_anomaly\_6hourly\_for\_Kelvin\_20220901\_20230630\.ncl

    - 输入数据：`GPM\_anomaly\_6hourly\_20220901\_20230630\.nc`

    - 输出数据：`GPM\_anomaly\_6hourly\_for\_Kelvin\_20220901\_20230630\.nc`

25. GPM\_anomaly\_6hourly\_for\_MJO\_20220901\_20230630\.ncl

    - 输入数据：`GPM\_anomaly\_6hourly\_20220901\_20230630\.nc`

    - 输出数据：`GPM\_anomaly\_6hourly\_for\_MJO\_20220901\_20230630\.nc`

26. GPM\_anomaly\_6hourly\_for\_MRG\_20220901\_20230630\.ncl

    - 输入数据：`GPM\_anomaly\_6hourly\_20220901\_20230630\.nc`

    - 输出数据：`GPM\_anomaly\_6hourly\_for\_MRG\_20220901\_20230630\.nc`

27. plot\_precip\_hovmuller\_6hourly\.m

    - 输入数据：`GPM\_anomaly\_6hourly\_20220901\_20230630\.nc`、`GPM\_anomaly\_6hourly\_for\_ER\_20220901\_20230630\.nc`、`GPM\_anomaly\_6hourly\_for\_Kelvin\_20220901\_20230630\.nc`、`GPM\_anomaly\_6hourly\_for\_MJO\_20220901\_20230630\.nc`、`GPM\_anomaly\_6hourly\_for\_MRG\_20220901\_20230630\.nc`

    - 输出图片：`Freddy\_Hovmoller\_Diagram\.png`

28. plot\_precip\_6hourly\_freddy\_box\.m

    - 输入数据：同上（一套6小时GPM异常及滤波数据）

    - 输出数据和图片：`Freddy\_Precipitation\_Data\.mat`、`Freddy\_Genesis\_Precipitation\_Anomaly\_Contributions\.png`、`Precipitation\_Contributions\_Subplots\_6hourly\.png`

29. calculate\_OLR\_anomaly\_daily\.m

    - 输入数据：`olr\-daily\_v01r02\_20090101\_20091231\.nc` … `olr\-daily\_v01r02\_20230101\_20231231\.nc`（15个年文件）

    - 输出数据：`olr\_anomaly\_daily\_20220101\_20231231\.nc`
    附：`climatology\_365day\.mat`、`fit\_climatology\_365day\.mat`、`Freddy\_OLR\_Data\.mat`、`mean\_olr\_15year\.mat`、`normalized\_olr\_2009\_2023\.mat`、`olr\_anomaly\_2022\_2023\_final\.mat`、`olr\_anomaly\_2022\_2023\_raw\.mat`

30. olr\_anomaly\_for\_ER\_daily\_20220101\_20231231\.ncl

    - 输入数据：`olr\_anomaly\_daily\_20220101\_20231231\.nc`

    - 输出数据：`olr\_anomaly\_for\_ER\_daily\_20220101\_20231231\.nc`

31. olr\_anomaly\_for\_Kelvin\_daily\_20220101\_20231231\.ncl

    - 输入数据：`olr\_anomaly\_daily\_20220101\_20231231\.nc`

    - 输出数据：`olr\_anomaly\_for\_Kelvin\_daily\_20220101\_20231231\.nc`

32. olr\_anomaly\_for\_MJO\_daily\_20220101\_20231231\.ncl

    - 输入数据：`olr\_anomaly\_daily\_20220101\_20231231\.nc`

    - 输出数据：`olr\_anomaly\_for\_MJO\_daily\_20220101\_20231231\.nc`

33. olr\_anomaly\_for\_MRG\_daily\_20220101\_20231231\.ncl

    - 输入数据：`olr\_anomaly\_daily\_20220101\_20231231\.nc`

    - 输出数据：`olr\_anomaly\_for\_MRG\_daily\_20220101\_20231231\.nc`

34. plot\_olr\_er\.m

    - 输入数据：`olr\_anomaly\_for\_ER\_daily\_20220101\_20231231\.nc`

    - 输出图片：`OLR\_anomaly\_ER\_20230201\.png` … `OLR\_anomaly\_ER\_20230210\.png`（10张）

35. plot\_olr\_kelvin\.m

    - 输入数据：`olr\_anomaly\_for\_Kelvin\_daily\_20220101\_20231231\.nc`

    - 输出图片：`OLR\_anomaly\_Kelvin\_20230201\.png` … `OLR\_anomaly\_Kelvin\_20230210\.png`（10张）

36. plot\_olr\_mjo\.m

    - 输入数据：`olr\_anomaly\_for\_MJO\_daily\_20220101\_20231231\.nc`

    - 输出图片：`OLR\_anomaly\_MJO\_20230201\.png` … `OLR\_anomaly\_MJO\_20230210\.png`（10张）

37. plot\_olr\_mrg\.m

    - 输入数据：`olr\_anomaly\_for\_MRG\_daily\_20220101\_20231231\.nc`

    - 输出图片：`OLR\_anomaly\_MRG\_20230201\.png` … `OLR\_anomaly\_MRG\_20230210\.png`（10张）

38. plot\_olr\_freddy\_box\.m

    - 输入数据：`olr\_anomaly\_daily\_20220101\_20231231\.nc`、`olr\_anomaly\_for\_ER\_daily\_20220101\_20231231\.nc`、`olr\_anomaly\_for\_Kelvin\_daily\_20220101\_20231231\.nc`、`olr\_anomaly\_for\_MJO\_daily\_20220101\_20231231\.nc`、`olr\_anomaly\_for\_MRG\_daily\_20220101\_20231231\.nc`

    - 输出图片：`Freddy\_Genesis\_OLR\_Anomaly\_Contributions\.png`、`OLR\_Contributions\_Subplots\.png`

39. calculate\_uv\_anomaly\_6hourly\.m

    - 输入数据：`ERA5\_dv\_q\_uv\_200901\_202312\_every\_6hours`

    - 输出数据：`u\_v\_anomaly\_6hourly\_20220101\_20231231\.nc`、`climatology\_fit\_850hPa\.mat`、`uv\_mean\_850hPa\.mat`

40. u\_v\_anomaly\_for\_ER\_6hourly\_20220101\_20231231\.ncl

    - 输入数据：`u\_v\_anomaly\_6hourly\_20220101\_20231231\.nc`

    - 输出数据：`u\_v\_anomaly\_for\_ER\_6hourly\_20220101\_20231231\.nc`

41. u\_v\_anomaly\_for\_Kelvin\_6hourly\_20220101\_20231231\.ncl

    - 输入数据：`u\_v\_anomaly\_6hourly\_20220101\_20231231\.nc`

    - 输出数据：`u\_v\_anomaly\_for\_Kelvin\_6hourly\_20220101\_20231231\.nc`

42. u\_v\_anomaly\_for\_MJO\_6hourly\_20220101\_20231231\.ncl

    - 输入数据：`u\_v\_anomaly\_6hourly\_20220101\_20231231\.nc`

    - 输出数据：`u\_v\_anomaly\_for\_MJO\_6hourly\_20220101\_20231231\.nc`

43. u\_v\_anomaly\_for\_MRG\_6hourly\_20220101\_20231231\.ncl

    - 输入数据：`u\_v\_anomaly\_6hourly\_20220101\_20231231\.nc`

    - 输出数据：`u\_v\_anomaly\_for\_MRG\_6hourly\_20220101\_20231231\.nc`

44. plot\_u\_anomaly\_6hourly\_freddy\_box\.m

    - 输入数据：`u\_v\_anomaly\_6hourly\_20220101\_20231231\.nc`、`u\_v\_anomaly\_for\_ER\_6hourly\_20220101\_20231231\.nc`、`u\_v\_anomaly\_for\_Kelvin\_6hourly\_20220101\_20231231\.nc`、`u\_v\_anomaly\_for\_MJO\_6hourly\_20220101\_20231231\.nc`、`u\_v\_anomaly\_for\_MRG\_6hourly\_20220101\_20231231\.nc`

    - 输出数据和图片：`Freddy\_U\_Wind\_Data\_6hourly\.mat`、`Freddy\_Genesis\_U\_Wind\_Anomaly\_Contributions\_6hourly\.png`、`U\_Wind\_Contributions\_Subplots\_6hourly\.png`

45. calculate\_VIMD\_6hourly\.m

    - 输入数据：`ERA5\_dv\_q\_uv\_200901\_202312\_every\_6hours`

    - 输出数据：`VIMD\_200901\_202312\_every\_6hours`（逐月文件）

46. calculate\_VIMD\_anomaly\_6hourly\.m

    - 输入数据：`VIMD\_200901\_202312\_every\_6hours`（全部月文件）

    - 输出数据：`VIMD\_anomaly\_6hourly\_20220101\_20231231\.nc`、`mean\_vimd\_15year\.mat`、`vimd\_standardized\_2022\_2023\.mat`

47. VIMD\_anomaly\_for\_ER\_6hourly\_20220101\_20231231\.ncl

    - 输入数据：`VIMD\_anomaly\_6hourly\_20220101\_20231231\.nc`

    - 输出数据：`VIMD\_anomaly\_for\_ER\_6hourly\_20220101\_20231231\.nc`

48. VIMD\_anomaly\_for\_Kelvin\_6hourly\_20220101\_20231231\.ncl

    - 输入数据：`VIMD\_anomaly\_6hourly\_20220101\_20231231\.nc`

    - 输出数据：`VIMD\_anomaly\_for\_Kelvin\_6hourly\_20220101\_20231231\.nc`

49. VIMD\_anomaly\_for\_MJO\_6hourly\_20220101\_20231231\.ncl

    - 输入数据：`VIMD\_anomaly\_6hourly\_20220101\_20231231\.nc`

    - 输出数据：`VIMD\_anomaly\_for\_MJO\_6hourly\_20220101\_20231231\.nc`

50. VIMD\_anomaly\_for\_MRG\_6hourly\_20220101\_20231231\.ncl

    - 输入数据：`VIMD\_anomaly\_6hourly\_20220101\_20231231\.nc`

    - 输出数据：`VIMD\_anomaly\_for\_MRG\_6hourly\_20220101\_20231231\.nc`

51. plot\_vimd\_freddy\_box\.m

    - 输入数据：`VIMD\_anomaly\_6hourly\_20220101\_20231231\.nc`、`VIMD\_anomaly\_for\_ER\_6hourly\_20220101\_20231231\.nc`、`VIMD\_anomaly\_for\_Kelvin\_6hourly\_20220101\_20231231\.nc`、`VIMD\_anomaly\_for\_MJO\_6hourly\_20220101\_20231231\.nc`、`VIMD\_anomaly\_for\_MRG\_6hourly\_20220101\_20231231\.nc`

    - 输出数据和图片：`Freddy\_VIMD\_Data\.mat`、`Freddy\_Genesis\_VIMD\_Anomaly\_Contributions\.png`、`VIMD\_Contributions\_Subplots\.png`

52. calculate\_divergence\_anomaly\_6hourly\.m

    - 输入数据：`ERA5\_dv\_q\_uv\_200901\_202312\_every\_6hours`

    - 输出数据：`divergence\_anomaly\_6hourly\_20220101\_20231231\.nc`

53. divergence\_anomaly\_for\_ER\_6hourly\_20220101\_20231231\.ncl

    - 输入数据：`divergence\_anomaly\_6hourly\_20220101\_20231231\.nc`

    - 输出数据：`divergence\_anomaly\_for\_ER\_6hourly\_20220101\_20231231\.nc`

54. divergence\_anomaly\_for\_Kelvin\_6hourly\_20220101\_20231231\.ncl

    - 输入数据：`divergence\_anomaly\_6hourly\_20220101\_20231231\.nc`

    - 输出数据：`divergence\_anomaly\_for\_Kelvin\_6hourly\_20220101\_20231231\.nc`

55. divergence\_anomaly\_for\_MJO\_6hourly\_20220101\_20231231\.ncl

    - 输入数据：`divergence\_anomaly\_6hourly\_20220101\_20231231\.nc`

    - 输出数据：`divergence\_anomaly\_for\_MJO\_6hourly\_20220101\_20231231\.nc`

56. divergence\_anomaly\_for\_MRG\_6hourly\_20220101\_20231231\.ncl

    - 输入数据：`divergence\_anomaly\_6hourly\_20220101\_20231231\.nc`

    - 输出数据：`divergence\_anomaly\_for\_MRG\_6hourly\_20220101\_20231231\.nc`

57. plot\_div\_vortex\_stretching\_er\.m

    - 输入数据：`ERA5\_dv\_q\_uv\_200901\_202312\_every\_6hours`、`divergence\_anomaly\_for\_ER\_6hourly\_20220101\_20231231\.nc`

    - 输出图片：`ER\_Freddy\_Individual\_Time\_Series\.png`、`Freddy\_Genesis\_Box\_ER\_Vortex\_Stretching\.png`

58. plot\_div\_vortex\_stretching\_kelvin\.m

    - 输入数据：`ERA5\_dv\_q\_uv\_200901\_202312\_every\_6hours`、`divergence\_anomaly\_for\_Kelvin\_6hourly\_20220101\_20231231\.nc`

    - 输出图片：`Kelvin\_Freddy\_Individual\_Time\_Series\.png`、`Freddy\_Genesis\_Box\_CCKW\_Vortex\_Stretching\.png`

59. plot\_div\_vortex\_stretching\_mjo\.m

    - 输入数据：`ERA5\_dv\_q\_uv\_200901\_202312\_every\_6hours`、`divergence\_anomaly\_for\_MJO\_6hourly\_20220101\_20231231\.nc`

    - 输出图片：`MJO\_Freddy\_Individual\_Time\_Series\.png`、`Freddy\_Genesis\_Box\_MJO\_Vortex\_Stretching\.png`

60. plot\_div\_vortex\_stretching\_mrg\.m

    - 输入数据：`ERA5\_dv\_q\_uv\_200901\_202312\_every\_6hours`、`divergence\_anomaly\_for\_MRG\_6hourly\_20220101\_20231231\.nc`

    - 输出图片：`MRG\_Freddy\_Individual\_Time\_Series\.png`、`Freddy\_Genesis\_Box\_MRG\_Vortex\_Stretching\.png`

61. plot\_vortex\_stretching\_3D\_er\.m

    - 输入数据：`ERA5\_dv\_q\_uv\_200901\_202312\_every\_6hours`、`IBTrACS\.ALL\.v04r00\.nc`、`divergence\_anomaly\_for\_ER\_6hourly\_20220101\_20231231\.nc`

    - 输出图片：`er\_vortex\_stretching\_3d`（系列图片）

62. plot\_vortex\_stretching\_3D\_kelvin\.m

    - 输入数据：`ERA5\_dv\_q\_uv\_200901\_202312\_every\_6hours`、`IBTrACS\.ALL\.v04r00\.nc`、`divergence\_anomaly\_for\_Kelvin\_6hourly\_20220101\_20231231\.nc`

    - 输出图片：`cckw\_vortex\_stretching\_3d`（系列图片）

63. plot\_vortex\_stretching\_3D\_mjo\.m

    - 输入数据：`ERA5\_dv\_q\_uv\_200901\_202312\_every\_6hours`、`IBTrACS\.ALL\.v04r00\.nc`、`divergence\_anomaly\_for\_MJO\_6hourly\_20220101\_20231231\.nc`

    - 输出图片：`mjo\_vortex\_stretching\_3d`（系列图片）

64. plot\_vortex\_stretching\_3D\_mrg\.m

    - 输入数据：`ERA5\_dv\_q\_uv\_200901\_202312\_every\_6hours`、`IBTrACS\.ALL\.v04r00\.nc`、`divergence\_anomaly\_for\_MRG\_6hourly\_20220101\_20231231\.nc`

    - 输出图片：`mrg\_vortex\_stretching\_3d`（系列图片）

65. plot\_q\_freddy\_box\.m

    - 输入数据：`ERA5\_dv\_q\_uv\_200901\_202312\_every\_6hours`

    - 输出图片：`Freddy\_GenesisBox\_RelativeHumidity\_Fig8a\.png`、`Freddy\_RH\_Analysis\_Detailed\.png`

66. Freddy \&amp; Dingani\_Tracks\_\(2023\)\.py

    - 输入数据：`IBTrACS\.ALL\.v04r00\.nc`

    - 输出图片：`Tropical\_Cyclones\_Freddy\_\&amp;\_Dingani\_Tracks\_\(2023\)\.png`

67. sst\_with\_full\_track\.py

    - 输入数据：`IBTrACS\.ALL\.v04r00\.nc`、`ERA5\_monthly\_averaged\_data\_on\_pressure\_levels\.nc`

    - 输出图片：`sst\_with\_full\_track\.png`

68. wind\_and\_precipitation\.py

    - 输入数据：`ERA5\_hourly\_data\_on\_850hPa\_20230101\_20230331\_Divergence\_Relativehumidity\_U\_V\.nc`、`GPM\_3IMERGDF\_07\-20230201\_20230331\_daily`

    - 输出图片：`Freddy\_20230201\.png` … `Freddy\_20230210\.png`（10张）

69. Monthly\_Mean\_Vertical\_Wind\_Shear\.py

    - 输入数据：`IBTrACS\.ALL\.v04r00\.nc`、`ERA5\_monthly\_averaged\_data\_on\_pressure\_levels\.nc`

    - 输出图片：`vertical\_shear\_feb\.png`、`vertical\_shear\_mar\.png`

70. mean\_specific\_humidity\_at\_850\_Pa\.py

    - 输入数据：`ERA5\_850hPa\_specific\_humidity\_20230203\_20230314\.nc`

    - 输出图片：`Mean Specific Humidity \(q\) at 850 hPa \(Feb 3 \- Mar 14, 2023\)\.png`

---

## 5\. 波数 \- 频率滤波（Wheeler\-Kiladis 方法）

### 5\.1 Wheeler\-Kiladis 滤波方法概述

Wheeler\-Kiladis 波数 \- 频率滤波基于线性浅水波理论，利用不同赤道波动的色散关系在波数 \- 频率域中的独特分布进行信号分离。

**基本原理**：

1. 对时空数据进行二维傅里叶变换，得到波数 \- 频率谱

2. 基于浅水方程的色散关系确定各波型在波数 \- 频率域中的理论分布区域

3. 设计带通滤波器，仅保留目标波型对应的波数 \- 频率范围

4. 逆向 FFT 重建时空域的滤波信号

**kf\_filter 函数调用格式**：

```ncl
filtered_data = kf_filter(
    data,        // 二维数组 (time × lon)
    obsPerDay,   // 每天观测次数
    tMin, tMax,  // 周期范围（天）
    kMin, kMax,  // 波数范围（正=东传，负=西传）
    hMin, hMax,  // 等效深度范围（米）
    waveName     // 波型名称
)
```

### 5\.2 NCL 滤波环境配置

**环境变量设置**：

```bash
# 设置NCL路径
export NCARG_ROOT=/path/to/ncl
export PATH=$NCARG_ROOT/bin:$PATH
export NCARG_LIB=$NCARG_ROOT/lib

# 验证kf_filter.ncl位置
find $NCARG_ROOT -name "kf_filter.ncl"
```

**通用 NCL 脚本模板**：

```ncl
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/kf_filter.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

begin
    ; 读取输入文件
    f = addfile("input_file.nc", "r")
    data = f->variable_name
    
    ; 设置维度和坐标
    data!0 = "time"
    data!1 = "lon"
    data!2 = "lat"
    
    ; 创建输出数组
    filtered = new(dimsizes(data), float)
    
    ; 对每个纬度进行滤波
    do i = 0, dimsizes(lat)-1
        data_slice = data(time|:, lon|:, lat|i)
        filtered(:,:,i) = kf_filter(data_slice, obsPerDay, \
                                    tMin, tMax, kMin, kMax, \
                                    hMin, hMax, waveName)
    end do
    
    ; 保存结果
    outfile = "output_file.nc"
    system("rm -f " + outfile)
    a = addfile(outfile, "c")
    a->filtered_variable = filtered
end
```

### 5\.3 MJO 滤波：参数设置、物理意义、输入输出

**MJO 滤波参数**：

|参数|值|物理意义|
|---|---|---|
|tMin|30 天|最小周期|
|tMax|96 天|最大周期|
|kMin|1|最小纬向波数|
|kMax|9|最大纬向波数|
|hMin|0\.01 m|最小等效深度|
|hMax|120 m|最大等效深度|
|obsPerDay|4|6 小时数据，每天 4 个观测|
|传播方向|东传|波数为正|

**输入输出文件**：

|数据类型|输入文件|输出文件|
|---|---|---|
|GPM 6 小时|`GPM\_anomaly\_6hourly\_20220901\_20230630\.nc`|`GPM\_anomaly\_6hourly\_for\_MJO\_20220901\_20230630\.nc`|
|GPM 日|`GPM\_anomaly\_daily\_\*\.nc`|`GPM\_anomaly\_daily\_for\_MJO\_\*\.nc`|
|风场 6 小时|`u\_v\_anomaly\_6hourly\_\*\.nc`|`u\_v\_anomaly\_6hourly\_for\_MJO\_\*\.nc`|
|风场日|`u\_v\_anomaly\_daily\_\*\.nc`|`u\_v\_anomaly\_daily\_for\_MJO\_\*\.nc`|
|VIMD|`VIMD\_anomaly\_6hourly\_\*\.nc`|`VIMD\_anomaly\_6hourly\_for\_MJO\_\*\.nc`|
|散度|`divergence\_anomaly\_6hourly\_\*\.nc`|`divergence\_anomaly\_6hourly\_for\_MJO\_\*\.nc`|
|OLR|`olr\_anomaly\_daily\_\*\.nc`|`olr\_anomaly\_daily\_for\_MJO\_\*\.nc`|

**物理意义**：
MJO（Madden\-Julian Oscillation）是热带大气中最显著的季节内振荡信号，周期 30\-90 天，向东传播。它通过调制大尺度环流和对流环境，为热带气旋生成提供有利背景。

### 5\.4 Kelvin 波滤波：参数设置、物理意义、输入输出

**Kelvin 波滤波参数**：

|参数|值|物理意义|
|---|---|---|
|tMin|2\.5 天|最小周期|
|tMax|17\.0 天|最大周期|
|kMin|1|最小纬向波数|
|kMax|14|最大纬向波数|
|hMin|8\.0 m|最小等效深度|
|hMax|90\.0 m|最大等效深度|
|obsPerDay|4|每天 4 个观测|
|传播方向|东传|波数为正|

**等效深度与相速度关系**：

$c = \sqrt{gh}$

其中 $g = 9.8 , \text{m/s}^2$，等效深度 h=8\-90m 对应相速度约 8\.9\-29\.7 m/s。

**物理意义**：
赤道 Kelvin 波是一种向东传播的重力波，只存在于赤道附近。它在对流层低层表现为气压场和风场的耦合扰动，能够触发和组织对流活动。

### 5\.5 ER 波（赤道罗斯贝波）滤波：参数设置、物理意义、输入输出

**ER 波滤波参数**：

|参数|值|物理意义|
|---|---|---|
|tMin|9\.7 天|最小周期|
|tMax|48\.0 天|最大周期|
|kMin|\-1|最小波数（向西传播）|
|kMax|\-10|最大波数（向西传播）|
|hMin|5\.0 m|最小等效深度|
|hMax|90\.0 m|最大等效深度|
|obsPerDay|4|每天 4 个观测|
|传播方向|西传|波数为负|

**物理意义**：
赤道罗斯贝波（Equatorial Rossby waves）是向西传播的大尺度波动，周期较长（10\-50 天）。它们通过涡度平流和能量频散影响热带气旋生成环境。

### 5\.6 MRG 波（混合罗斯贝重力波）滤波：参数设置、物理意义、输入输出

**MRG 波滤波参数**：

|参数|值|物理意义|
|---|---|---|
|tMin|3\.0 天|最小周期|
|tMax|20\.0 天|最大周期|
|kMin|\-1|最小波数（向西传播）|
|kMax|\-10|最大波数（向西传播）|
|hMin|8\.0 m|最小等效深度|
|hMax|90\.0 m|最大等效深度|
|obsPerDay|4|每天 4 个观测|
|传播方向|西传|波数为负|

**物理意义**：
混合罗斯贝重力波（Mixed Rossby\-Gravity waves）是一种介于罗斯贝波和惯性重力波之间的波动类型，周期 3\-20 天，向西传播。它们在热带气旋生成中扮演重要的触发角色。

### 5\.7 滤波参数对照表

|波型|周期范围（天）|波数范围|传播方向|等效深度（m）|典型相速度（m/s）|
|---|---|---|---|---|---|
|**MJO**|30\-96|1\-9|东传|0\.01\-120|可变|
|**Kelvin**|2\.5\-17|1\-14|东传|8\-90|8\.9\-29\.7|
|**ER**|9\.7\-48|\-1 至 \- 10|西传|5\-90|7\.0\-29\.7|
|**MRG**|3\-20|\-1 至 \- 10|西传|8\-90|8\.9\-29\.7|

### 5\.8 滤波结果质量评估方法

**评估指标**：

```ncl
; 1. 能量保留率
original_energy = sum(data^2)
filtered_energy = sum(filtered_data^2)
energy_ratio = filtered_energy / original_energy

print("能量保留率: " + energy_ratio)
print("  预期范围: 0.1-0.4")

; 2. 频谱分析
; 对滤波前后数据进行功率谱分析，验证滤波效果

; 3. 相关性检查
corr = cor(data, filtered_data)
print("滤波前后相关系数: " + corr)
print("  预期范围: 0.3-0.7")
```

> ⏱️ **预计耗时**：单个变量的四种波动滤波约需 **2\-4 小时**，全部 7 个变量的滤波总计约需 **14\-28 小时**。
> 
> 

> 💡 **实用技巧**：滤波计算可以并行进行，建议同时运行多个 NCL 进程以节省时间。
> 
> 

---

## 6\. 部分结果分析与绘图举例

### 6\.1 论文图件举例说明

|图表名称|生成脚本|输入数据|输出文件名|
|---|---|---|---|
|Freddy \&amp; Dingani 路径图|`Freddy\_\&amp;\_Dingani\_Tracks\_\(2023\)\.py`|IBTrACS 数据|`Freddy\_Dingani\_Tracks\.png`|
|四种波动 Hovmöller 图|`plot\_\*\_hovmoller\_diagram\.m`|滤波后降水数据|`\*\_Hovmoller\_Diagram\.png`|
|降水与风场异常空间分布|`plot\_precip\_uv\_\*\.m`|滤波后降水 \+ 风场数据|`precip\_uv\_\*\.png`|
|Freddy 生成区 Hovmöller 图|`plot\_precip\_hovmuller\_6hourly\.m`|GPM 6 小时异常数据|`Freddy\_Hovmoller\_Diagram\.png`|
|各变量波动贡献分解|`plot\_\*\_freddy\_box\.m`|区域平均时间序列|`\*\_freddy\_box\.png`|
|海温与垂直风切变|`sst\_with\_full\_track\.py`|ERA5 SST 数据|`SST\_with\_Tracks\.png`|
|涡旋拉伸时间序列|`plot\_div\_vortex\_stretching\_\*\.m`|散度 \+ 涡度数据|`vortex\_stretching\_\*\.png`|
|相对湿度垂直剖面|`plot\_q\_freddy\_box\.m`|ERA5 湿度数据|`RH\_vertical\_profile\.png`|

### 6\.2 Hovmöller 时空演变图绘制

**核心绘图逻辑**：

```matlab
% 定义研究区域
lon_min = 80;
lon_max = 180;
lat_min = -20;
lat_max = -10;
start_time = datetime(2023, 1, 1);
end_time = datetime(2023, 3, 31);

% 沿纬度方向平均
precip_avg = squeeze(mean(precip_region, 1, 'omitnan'));

% 创建图形
figure('Position', [100, 100, 800, 800]);

% 绘制降水异常填色图
h = imagesc(lon_region_numeric, time_region_numeric, precip_avg);
set(gca, 'YDir', 'normal');

% 自定义颜色映射：负值（浅蓝→白），正值（白→深红）
ncolors = 64;
neg_ratio = 0.13;  % 负值部分占13%
pos_ratio = 0.86;   % 正值部分占86%
white_ratio = 0.01; % 白色区域占1%

% 生成颜色映射...
colormap(cmap);

% 绘制各波列的等值线
contour(X, T, mjo_avg, [0.5, 1, 1.5, 2], 'k-', 'LineWidth', 1.6);
contour(X, T, kelvin_avg, [0.5, 1, 1.5, 2], 'b-', 'LineWidth', 1.6);
contour(X, T, mrg_avg, [0.5, 1, 1.5, 2], 'g-', 'LineWidth', 1.6);
contour(X, T, er_avg, [0.5, 1, 1.5, 2], 'r-', 'LineWidth', 1.6);

% 标记Freddy生成位置（洋红色方框）
rectangle('Position', [110, freddy_gen_time_num-1, 10, 2], ...
    'EdgeColor', 'magenta', 'LineWidth', 2.5);
```

**物理意义**：
Hovmöller 图是诊断热带波动传播的关键工具。通过对生成纬度带（10°S\-20°S）内的降水异常做经度平均，将三维数据压缩为二维，可以清晰展示不同波动的向东或向西传播特征。

### 6\.3 降水与风场合成图绘制

**脚本**：`plot\_precip\_uv\_mjo\.m`、`plot\_precip\_uv\_kelvin\.m`、`plot\_precip\_uv\_mrg\.m`、`plot\_precip\_uv\_er\.m`

**核心绘图逻辑**：

```matlab
% 输入：滤波后的降水异常和风场异常数据
% 输出：10张日合成图（2023-02-01至2023-02-10）

% 降水数据采用自定义暖色系填色
contourf(lon, lat, squeeze(precip(:,:,t))', 20, 'LineStyle', 'none');
colormap(hot_colormap);
caxis([0, 10]);

% 风场数据用黑色箭头绘制
hold on;
quiver(lon(1:wind_skip:end), lat(1:wind_skip:end), ...
       u(1:wind_skip:end, 1:wind_skip:end, t)', ...
       v(1:wind_skip:end, 1:wind_skip:end, t)', ...
       0.5, 'k');

% 叠加海岸线和赤道线
load coast;
plot(long, lat, 'k', 'LineWidth', 0.5);
yline(0, 'k--', 'LineWidth', 0.8);
```

### 6\.4 时间序列贡献分解图绘制

**通用逻辑**：

```matlab
% Freddy生成区：110°E-120°E, 10°S-20°S
box_lon = [110, 120];
box_lat = [-20, -10];

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

% 绘图
plot(time, original, 'k--', 'LineWidth', 1.5);
hold on;
plot(time, mjo_component, 'b-', 'LineWidth', 1.5);
plot(time, kelvin_component, 'r-', 'LineWidth', 1.5);
plot(time, mrg_component, 'g-', 'LineWidth', 1.5);
plot(time, er_component, 'm-', 'LineWidth', 1.5);
plot(time, sum_component, 'k-', 'LineWidth', 2);
```

### 6\.5 涡旋拉伸三维图绘制

**脚本**：`plot\_vortex\_stretching\_3D\_\*\.m`

**核心绘图逻辑**：

```matlab
% 坐标系统：X=经度(100°-130°E)，Y=纬度(25°S-5°S)，Z=涡旋拉伸项
% 视角：view([-35, 15])（西南方向俯视）

% 计算步骤：
% 1. 提取850hPa相对涡度
% 2. 计算绝对涡度：η = ζ + f
% 3. 提取散度异常
% 4. 计算涡旋拉伸项：η × (-divergence)

% 三维表面图
surf(lon, lat, vortex_stretching * 1e9);
shading interp;
colormap(blue_white_red_colormap);
alpha(0.7);

% z_min平面上绘制海岸线、Freddy位置、Genesis Box
hold on;
plot3(coast_lon, coast_lat, z_min*ones(size(coast_lon)), 'k', 'LineWidth', 0.5);
plot3(freddy_lon, freddy_lat, z_min, 'ro', 'MarkerSize', 10);
```

### 6\.6 图形美化参数设置

**颜色设置**：

```matlab
% 自定义红蓝颜色映射（异常场）
function cmap = redblue_colormap(n)
    if nargin < 1, n = 64; end
    cmap = zeros(n, 3);
    half = floor(n/2);
    
    % 蓝色部分（负值）
    for i = 1:half
        ratio = (i-1)/(half-1);
        cmap(i, :) = [0.2 + 0.8*ratio, 0.3 + 0.7*ratio, 1.0];
    end
    
    % 红色部分（正值）
    for i = half+1:n
        ratio = (i-half-1)/(n-half-1);
        cmap(i, :) = [1.0, 0.6 - 0.6*ratio, 0.4 - 0.4*ratio];
    end
end
```

**字体设置**：

```matlab
% 统一字体设置
set(gca, 'FontName', 'Arial', 'FontSize', 12);
xlabel('Longitude (°E)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Latitude (°N)', 'FontSize', 14, 'FontWeight', 'bold');
title('Title', 'FontSize', 16, 'FontWeight', 'bold');
```

**输出设置**：

```matlab
% 高分辨率输出
print(gcf, 'output.png', '-dpng', '-r300');
```

---

## 7\. Python 辅助脚本详解

### 7\.1 Python 脚本索引表

|脚本名称|功能|输入文件|输出文件|
|---|---|---|---|
|`Freddy\_\&amp;\_Dingani\_Tracks\_\(2023\)\.py`|绘制 TC 路径轨迹|\[IBTrACS\.SI\.v04r01\.nc\]|`Freddy\_Dingani\_Tracks\.png`|
|`Monthly\_Mean\_Vertical\_Wind\_Shear\.py`|计算垂直风切变|ERA5 uv 数据|`Vertical\_Wind\_Shear\.png`|
|`mean\_specific\_humidity\_at\_850 \_Pa\.py`|绘制 850hPa 比湿|ERA5 q 数据|`Specific\_Humidity\_850hPa\.png`|
|`sst\_with\_full\_track\.py`|海温与路径叠加|ERA5 SST \+ IBTrACS|`SST\_with\_Tracks\.png`|
|`wind\_and\_precipitation\.py`|风场与降水合成|ERA5 uv \+ GPM|`Wind\_Precipitation\.png`|

### 7\.2 热带气旋路径绘制脚本详解

**脚本**：`Freddy\_\&amp;\_Dingani\_Tracks\_\(2023\)\.py`

```python
import xarray as xr
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import numpy as np

def find_storm_index(dataset, target_sid):
    """在IBTrACS数据中查找特定风暴的索引"""
    sids = dataset['sid'].values
    for i, sid in enumerate(sids):
        if sid == target_sid:
            return i
    return None

def extract_track(dataset, idx):
    """提取风暴路径数据"""
    time = dataset['time'][idx].values
    lat = dataset['lat'][idx].values
    lon = dataset['lon'][idx].values
    valid = (lat > -90) & (lon > -180) & (~np.isnat(time))
    return time[valid], lat[valid], lon[valid]

# 主程序
ds = xr.open_dataset("IBTrACS.SI.v04r01.nc")
freddy_sid = b'2023036S12117'  # Freddy: 2023年第36天, 南纬12°, 东经117°

freddy_idx = find_storm_index(ds, freddy_sid)
freddy_time, freddy_lat, freddy_lon = extract_track(ds, freddy_idx)

# 绘图
fig = plt.figure(figsize=(10, 8))
ax = plt.axes(projection=ccrs.PlateCarree())
ax.coastlines()
ax.gridlines(draw_labels=True)

ax.plot(freddy_lon, freddy_lat, 'r-', linewidth=2, transform=ccrs.PlateCarree())
ax.scatter(freddy_lon[::4], freddy_lat[::4], c='red', s=50, transform=ccrs.PlateCarree())

plt.savefig('Freddy_Track.png', dpi=300, bbox_inches='tight')
```

**执行命令**：

```bash
python Freddy_&_Dingani_Tracks_(2023).py
```

### 7\.3 垂直风切变计算脚本详解

**脚本**：`Monthly\_Mean\_Vertical\_Wind\_Shear\.py`

**核心计算**：

```python
def calculate_vertical_shear(ds):
    """
    计算200-850hPa垂直风切变
    
    数学原理:
        VWS = √[(u200 - u850)² + (v200 - v850)²]
    
    物理意义:
        VWS < 10 m/s: 有利于发展
        VWS > 12 m/s: 抑制发展
    """
    u200 = ds['u'].sel(pressure_level=200, method='nearest')
    v200 = ds['v'].sel(pressure_level=200, method='nearest')
    u850 = ds['u'].sel(pressure_level=850, method='nearest')
    v850 = ds['v'].sel(pressure_level=850, method='nearest')
    return np.sqrt((u200 - u850)**2 + (v200 - v850)**2)
```

### 7\.4 海温与路径叠加脚本详解

**关键技术点**：

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

# 使用patheffects实现路径的白边描边
import matplotlib.patheffects as pe
path_effects = [pe.Stroke(linewidth=3, foreground='white'), pe.Normal()]
ax.plot(track_lon, track_lat, 'r-', linewidth=2, path_effects=path_effects)
```

---

## 8\. 完整代码运行顺序

### 8\.1 整体运行流程图

```mermaid
graph TD
    A[环境配置与验证] --> B[数据下载与完整性检查]
    B --> C[GPM数据预处理]
    B --> D[ERA5数据预处理]
    B --> E[OLR数据预处理]
    C --> F[GPM异常场计算]
    D --> G[风场异常场计算]
    D --> H[VIMD计算]
    H --> I[VIMD异常场计算]
    D --> J[散度异常场计算]
    E --> K[OLR异常场计算]
    F & G & I & J & K --> L[波数-频率滤波]
    L --> M[MJO滤波]
    L --> N[Kelvin波滤波]
    L --> O[ER波滤波]
    L --> P[MRG波滤波]
    M & N & O & P --> Q[结果分析与绘图]
    Q --> R[Hovmöller图]
    Q --> S[空间分布图]
    Q --> T[时间序列图]
    Q --> U[涡旋拉伸诊断]```

### 8\.2 第一步：环境配置与验证

⏱️ **预计耗时**：30 分钟

```bash
# 1. 克隆GitHub仓库
git clone https://github.com/CY18270852013/TC-Freddy-Tropical-Waves.git
cd TC-Freddy-Tropical-Waves

# 2. 创建Python环境
conda create -n tc-freddy python=3.9
conda activate tc-freddy
conda install -c conda-forge numpy pandas xarray netCDF4 scipy cartopy matplotlib

# 3. 安装NCL
conda install -c conda-forge ncl

# 4. 验证环境
ncl -V
python -c "import numpy, pandas, xarray, cartopy; print('Python环境OK')"
```

### 8\.3 第二步：数据下载与完整性检查

⏱️ **预计耗时**：8\-12 小时

```bash
# 1. 下载GPM数据（约50GB）
# 使用第2章提供的wget或Python脚本

# 2. 下载ERA5数据
python download_era5.py

# 3. 下载OLR和IBTrACS数据
wget ftp://ftp.cdc.noaa.gov/Datasets/interp_OLR/olr.day.mean.nc
wget "https://www.ncei.noaa.gov/data/international-best-track-archive-for-climate-stewardship-ibtracs/v04r01/access/netcdf/IBTrACS.SI.v04r01.nc"

# 4. 运行数据完整性检查脚本
matlab -nodisplay -r "check_data_integrity; exit;"
```

### 8\.4 第三步：数据预处理

⏱️ **预计耗时**：24\-36 小时

```matlab
% ===== GPM数据处理 =====
% 30分钟→6小时聚合
run('GPM_precipitation/6hourly/GPM_6hourly_Cumulative_Precipitation.m')
% ⏱️ 预计耗时：2-3小时

% 计算异常场
run('GPM_precipitation/6hourly/calculate_GPM_anomaly_6hourly.m')
% ⏱️ 预计耗时：4-6小时

% 日数据处理
run('GPM_precipitation/daily/calculate_GPM_precipitation_anomaly_daily.m')
% ⏱️ 预计耗时：3-5小时

% ===== ERA5数据处理 =====
% 3小时→日平均
run('ERA5_uv/daily/transfer_uv_3hourly_to_daily.m')
% ⏱️ 预计耗时：1-2小时

% 日异常场计算
run('ERA5_uv/daily/calculate_ERA5_u_v_anomaly_daily.m')
% ⏱️ 预计耗时：2-3小时

% 6小时异常场计算
run('ERA5_uv/6hourly/calculate_uv_anomaly_6hourly.m')
% ⏱️ 预计耗时：2-3小时

% VIMD计算
run('ERA5_VIMD/calculate_VIMD_6hourly.m')
% ⏱️ 预计耗时：8-12小时
% 💡 建议内存：32GB以上

run('ERA5_VIMD/calculate_VIMD_anomaly_6hourly.m')
% ⏱️ 预计耗时：2-3小时

% 散度计算
run('ERA5_divergence/calculate_divergence_anomaly_6hourly.m')
% ⏱️ 预计耗时：2-3小时

% ===== OLR数据处理 =====
run('OLR/calculate_OLR_anomaly_daily.m')
% ⏱️ 预计耗时：1-2小时
```

> 💡 **内存管理建议**：处理 VIMD 计算时，建议分月份处理，每处理完一个月后清理内存。
> 
> 

### 8\.5 第四步：波数 \- 频率滤波

⏱️ **预计耗时**：14\-28 小时

```bash
# GPM降水波动分离
cd GPM_precipitation/6hourly
ncl GPM_anomaly_for_MJO_6hourly_20220901_20230630.ncl
ncl GPM_anomaly_for_Kelvin_6hourly_20220901_20230630.ncl
ncl GPM_anomaly_for_ER_6hourly_20220901_20230630.ncl
ncl GPM_anomaly_for_MRG_6hourly_20220901_20230630.ncl
# ⏱️ 预计耗时：2-4小时
# 💡 建议内存：16GB以上

cd ../daily
ncl GPM_anomaly_daily_for_MJO_*.ncl
ncl GPM_anomaly_daily_for_Kelvin_*.ncl
ncl GPM_anomaly_daily_for_ER_*.ncl
ncl GPM_anomaly_daily_for_MRG_*.ncl

# 风场波动分离
cd ../../ERA5_uv/6hourly
ncl u_v_anomaly_for_MJO_*.ncl
ncl u_v_anomaly_for_Kelvin_*.ncl
ncl u_v_anomaly_for_ER_*.ncl
ncl u_v_anomaly_for_MRG_*.ncl

cd ../daily
ncl u_v_anomaly_for_MJO_daily_*.ncl
ncl u_v_anomaly_for_Kelvin_daily_*.ncl
ncl u_v_anomaly_for_ER_daily_*.ncl
ncl u_v_anomaly_for_MRG_daily_*.ncl

# VIMD波动分离
cd ../../ERA5_VIMD
ncl VIMD_anomaly_for_MJO_*.ncl
ncl VIMD_anomaly_for_Kelvin_*.ncl
ncl VIMD_anomaly_for_ER_*.ncl
ncl VIMD_anomaly_for_MRG_*.ncl

# 散度波动分离
cd ../ERA5_divergence
ncl divergence_anomaly_for_MJO_*.ncl
ncl divergence_anomaly_for_Kelvin_*.ncl
ncl divergence_anomaly_for_ER_*.ncl
ncl divergence_anomaly_for_MRG_*.ncl

# OLR波动分离
cd ../OLR
ncl olr_anomaly_for_MJO_*.ncl
ncl olr_anomaly_for_Kelvin_*.ncl
ncl olr_anomaly_for_ER_*.ncl
ncl olr_anomaly_for_MRG_*.ncl
```

> 💡 **并行处理建议**：可以同时运行 4 个 NCL 进程（MJO、Kelvin、ER、MRG）以节省时间。
> 
> 

### 8\.6 第五步：结果分析与绘图

⏱️ **预计耗时**：4\-8 小时

```bash
# Python图表生成
cd Python_codes
python Freddy_&_Dingani_Tracks_(2023).py
python mean_specific_humidity_at_850_Pa.py
python Monthly_Mean_Vertical_Wind_Shear.py
python sst_with_full_track.py
python wind_and_precipitation.py

# MATLAB图表生成
# 运行所有plot_*.m脚本
```

### 8\.7 路径配置文件修改说明

**修改所有 MATLAB 脚本中的数据路径**：

```matlab
% 原始路径（作者本地路径）
input_path = 'E:\Original_Data_of_Freddy\ERA5_dv_q_uv_200901_202312_every_6hours';
output_path = 'E:\Results_of_Freddy\VIMD_200901_202312_every_6hours';

% 修改为您的本地路径
input_path = '/your/path/to/data/ERA5/';
output_path = '/your/path/to/results/VIMD/';
```

> ⚠️ **重要**：所有脚本中的路径都是绝对路径，必须根据您的实际环境进行修改！
> 
> 

### 8\.8 内存管理与大文件处理建议

**内存优化技巧**：

```matlab
% 1. 使用single精度代替double
data = single(data);  % 内存占用减半

% 2. 及时清理不需要的变量
clear large_variable;

% 3. 分块处理大文件
for block = 1:num_blocks
    data_block = read_block(block);
    process(data_block);
    clear data_block;
end

% 4. 增加MATLAB堆内存大小
java.lang.Runtime.getRuntime.maxMemory / 1e9  % 显示最大内存
```

### 8\.9 常见运行错误与解决方案

|错误类型|可能原因|解决方案|
|---|---|---|
|**内存不足 \(Out of Memory\)**|数据量过大|分批次处理，使用 single 精度，增加系统内存|
|**NetCDF 读写错误**|路径包含中文或特殊字符|使用英文路径，检查文件完整性|
|**kf\_filter 返回全 NaN**|数据维度顺序错误|确保维度为 \(time, lon, lat\)|
|**滤波结果异常**|参数设置错误|检查 tMin/tMax/kMin/kMax 的取值范围|
|**NCL 找不到 kf\_filter**|contributed 脚本未正确安装|检查 $NCARG\_ROOT 路径设置|
|**傅里叶拟合出现复数**|FFT 处理不当|取实部：real \(ifft \(\.\.\.\)\)|

---

## 9\. 附录：关键方法原理

### 9\.1 Wheeler\-Kiladis 波数 \- 频率滤波数学原理详细推导

**时空傅里叶变换**：

对于时空场 $\psi(\lambda, t)$，其二维傅里叶变换为：

$\Psi(k, \omega) = \frac{1}{2\pi} \int_{-\infty}^{\infty} \int_{0}^{2\pi} \psi(\lambda, t) e^{-i(k\lambda - \omega t)} d\lambda dt$

其中：

- $k$ = 纬向波数

- $\omega$ = 角频率

**线性浅水方程色散关系**：

对于赤道波动，线性浅水方程给出色散关系：

$\omega^2 - c^2 k^2 = (2n+1) \beta c$

其中：

- $c = \sqrt{gh}$ = 重力波相速度

- $\beta = df/dy$ = 科氏参数经向梯度

- $n$ = 经向模数

**不同波动的色散关系**：

|波型|n|色散关系|
|---|---|---|
|Kelvin|\-1|$\omega = ck$|
|MRG|0|$\omega^2 = c^2 k^2 + \beta c$|
|ER|n ≥ 1|$\omega = -\beta k / (k^2 + (2n+1)\beta/c)$|

**滤波区域构建**：

在波数 \- 频率平面上，根据上述色散关系定义每个波型的允许区域，仅保留该区域内的傅里叶系数，然后进行逆变换得到滤波后的时空场。

### 9\.2 傅里叶拟合气候态计算方法

**傅里叶级数展开**：

$x(t) = \frac{a_0}{2} + \sum_{k=1}^{\infty} \left[ a_k \cos\left(\frac{2\pi k t}{T}\right) + b_k \sin\left(\frac{2\pi k t}{T}\right) \right]$

其中系数计算公式：

$a_0 = \frac{2}{T} \int_0^T x(t) dt$
$a_k = \frac{2}{T} \int_0^T x(t) \cos\left(\frac{2\pi k t}{T}\right) dt$
$b_k = \frac{2}{T} \int_0^T x(t) \sin\left(\frac{2\pi k t}{T}\right) dt$

**FFT 实现**：

在频域中，保留前 N\+1 个傅里叶系数（直流分量 \+ N 个谐波），其余置零，然后逆 FFT 得到平滑的气候态。

### 9\.3 涡度方程与涡旋拉伸项推导

**完整的涡度方程**：

$\frac{D\zeta}{Dt} = -(\zeta + f) \nabla \cdot \mathbf{V} - \mathbf{V} \cdot \nabla f + \left( \frac{\partial w}{\partial y} \frac{\partial u}{\partial z} - \frac{\partial w}{\partial x} \frac{\partial v}{\partial z} \right) + \frac{1}{\rho^2} \left( \frac{\partial \rho}{\partial x} \frac{\partial p}{\partial y} - \frac{\partial \rho}{\partial y} \frac{\partial p}{\partial x} \right)$

**涡旋拉伸项**：

在热带气旋生成的早期阶段，涡旋拉伸项是最主要的涡度增长机制：

$\frac{D\zeta}{Dt} \approx -(\zeta + f) \nabla \cdot \mathbf{V} = \eta \frac{\partial w}{\partial z}$

根据连续性方程：

$\nabla \cdot \mathbf{V} = -\frac{\partial w}{\partial z}$

因此：

$\frac{D\zeta}{Dt} \approx \eta \frac{\partial w}{\partial z} = \eta \cdot (-\nabla \cdot \mathbf{V})$

这就是本研究中使用的涡旋拉伸项诊断公式。

### 9\.4 VIMD 物理意义与计算公式推导

**水汽通量散度**：

单位面积气柱内的水汽收支方程为：

$\frac{\partial}{\partial t} \int_{p_s}^{p_t} q \frac{dp}{g} = -\int_{p_s}^{p_t} \nabla \cdot (q\mathbf{V}) \frac{dp}{g} + (E - P)$

其中：

- 左边 = 气柱内水汽的局地变化

- 右边第一项 = 水汽通量的水平辐合

- 右边第二项 = 表面蒸发减降水

**VIMD 定义**：

垂直积分的水汽通量辐合（VIMD）定义为：

$\text{VIMD} = -\frac{1}{g} \int_{p_s}^{p_t} \nabla \cdot (q\mathbf{V}) dp$

VIMD 的正值表示水汽辐合，是对流发展和降水发生的必要条件。

### 9\.5 波动能量诊断方法

**波动动能**：

$K' = \frac{1}{2} (u'^2 + v'^2)$

**波动有效位能**：

$A' = \frac{g^2}{2N^2} \left( \frac{\theta'}{\bar{\theta}} \right)^2$

**能量转换项**：

$C(A', K') = -\frac{g}{\bar{\theta}} \overline{w' \theta'}$

### 9\.6 参考文献列表

1. Wheeler, M\. and G\.N\. Kiladis \(1999\)\. Convectively coupled equatorial waves: Analysis of clouds and temperature in the wavenumber\-frequency domain\. *Journal of the Atmospheric Sciences*, 56, 374\-399\.

2. Kiladis, G\.N\., et al\. \(2005\)\. A comparison of the MJO and convectively coupled equatorial waves during TOGA COARE\. *Journal of the Atmospheric Sciences*, 62, 2762\-2779\.

3. Matsuno, T\. \(1966\)\. Quasi\-geostrophic motions in the equatorial area\. *Journal of the Meteorological Society of Japan*, 44, 25\-43\.

4. Huffman, G\.J\., et al\. \(2019\)\. GPM IMERG Final Precipitation L3 Half Hourly 0\.1 degree x 0\.1 degree V06\.

5. Hersbach, H\., et al\. \(2020\)\. The ERA5 global reanalysis\. *Quarterly Journal of the Royal Meteorological Society*\.

6. Liebmann, B\. and C\.A\. Smith \(1996\)\. Description of a complete \(interpolated\) outgoing longwave radiation dataset\. *Bulletin of the American Meteorological Society*, 77, 1275\-1277\.

7. Knapp, K\.R\., et al\. \(2010\)\. International Best Track Archive for Climate Stewardship \(IBTrACS\): Unifying tropical cyclone best track data\. *Bulletin of the American Meteorological Society*, 91, 363\-376\.

### 9\.7 常见问题 FAQ

**Q: 为什么我的滤波结果全是 NaN？**
A: 检查数据维度顺序是否为 \(time, lon, lat\)，kf\_filter 函数对维度顺序很敏感。

**Q: VIMD 计算结果的符号为什么与预期相反？**
A: VIMD 定义中包含负号，正值表示辐合。请检查公式中的 \- 1/g 因子。

**Q: 为什么需要 15 年的数据来计算气候态？**
A: 足够长的时间序列可以更准确地估计年循环，减少年际变率的影响。

**Q: 可以只处理 2023 年的数据吗？**
A: 不行。异常场计算需要 15 年的基期数据来计算气候态。

**Q: 内存不足怎么办？**
A: 分年度处理，使用 single 精度，及时清理不需要的变量。

---

**技术支持**：如有问题，请在 GitHub 仓库提交 Issue。

**许可证**：MIT License



> （注：文档部分内容可能由 AI 生成）
