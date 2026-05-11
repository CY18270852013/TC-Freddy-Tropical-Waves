# TC-Freddy-Tropical-Waves 技术文档

**论文题目**：热带气旋“弗雷迪”（2023）生成过程中的热带波动作用分析
**作者**：陈勇
**版本**：v2.0
**最后更新**：2026 年 5 月 11 日
**仓库地址**：[https://github.com/CY18270852013/TC-Freddy-Tropical-Waves](https://github.com/CY18270852013/TC-Freddy-Tropical-Waves)

\---

## 目录

1. \[项目概述]

   * 1.1 研究背景与科学问题
   * 1.2 研究内容与技术路线图
   * 1.3 GitHub 仓库文件结构总览
   * 1.4 复现预期结果说明
2. \[数据获取与准备]

   * 2.1 数据源详细信息表
   * 2.2 GPM IMERG 降水数据详细下载步骤
   * 2.3 ERA5 再分析数据详细下载步骤
   * 2.4 NOAA OLR 射出长波辐射数据下载
   * 2.5 IBTrACS 台风最佳路径数据下载
   * 2.6 推荐的数据目录结构
   * 2.7 数据完整性检查方法
3. \[软件环境要求]

   * 3.1 MATLAB 版本要求与工具箱依赖
   * 3.2 Python 版本要求与依赖库列表
   * 3.3 NCL 环境配置
   * 3.4 环境验证脚本与测试方法
   * 3.5 硬件配置建议
4. \[数据预处理流程]

   * 4.1 预处理整体流程图
   * 4.2 气候态计算与去除（傅里叶拟合方法）
   * 4.3 异常场计算方法
   * 4.4 VIMD（垂直积分水汽辐合）详细计算
   * 4.5 涡旋拉伸项动力诊断计算
   * 4.6 每个 MATLAB 预处理脚本详解
   * 4.7 预处理结果验证方法
5. \[波数 - 频率滤波（Wheeler-Kiladis 方法）]

   * 5.1 Wheeler-Kiladis 滤波方法概述
   * 5.2 NCL 滤波环境配置
   * 5.3 MJO 滤波：参数设置、物理意义、输入输出
   * 5.4 Kelvin 波滤波：参数设置、物理意义、输入输出
   * 5.5 ER 波（赤道罗斯贝波）滤波：参数设置、物理意义、输入输出
   * 5.6 MRG 波（混合罗斯贝重力波）滤波：参数设置、物理意义、输入输出
   * 5.7 滤波参数对照表
   * 5.8 滤波结果质量评估方法
6. \[结果分析与绘图]

   * 6.1 论文图件索引表
   * 6.2 台风路径与强度演变图绘制
   * 6.3 Hovmöller 时空演变图绘制
   * 6.4 波动空间分布图绘制
   * 6.5 时间序列与功率谱分析图绘制
   * 6.6 波动贡献定量分析图绘制
   * 6.7 每个绘图脚本详解
   * 6.8 图形美化参数设置
7. \[Python 辅助脚本详解]

   * 7.1 Python 脚本索引表
   * 7.2 数据下载类脚本详解
   * 7.3 数据格式转换类脚本详解
   * 7.4 统计分析类脚本详解
   * 7.5 每个脚本的：输入文件、输出文件、执行命令、注意事项
8. \[完整代码运行顺序]

   * 8.1 整体运行流程图（Mermaid 流程图）
   * 8.2 第一步：环境配置与验证
   * 8.3 第二步：数据下载与完整性检查
   * 8.4 第三步：数据预处理
   * 8.5 第四步：波数 - 频率滤波
   * 8.6 第五步：结果分析与绘图
   * 8.7 路径配置文件修改说明
   * 8.8 内存管理与大文件处理建议
   * 8.9 常见运行错误与解决方案
9. \[附录：关键方法原理]

   * 9.1 Wheeler-Kiladis 波数 - 频率滤波数学原理详细推导
   * 9.2 傅里叶拟合气候态计算方法
   * 9.3 涡度方程与涡旋拉伸项推导
   * 9.4 VIMD 物理意义与计算公式推导
   * 9.5 波动能量诊断方法
   * 9.6 参考文献列表
   * 9.7 常见问题 FAQ

\---

## 1\. 项目概述

### 1.1 研究背景与科学问题

热带气旋 Freddy（2023）是有记录以来持续时间最长、累积气旋能量（ACE）最高的热带气旋之一，在南印度洋经历了两次增强 - 减弱 - 再增强的过程，对马达加斯加、莫桑比克等国造成了严重影响。Freddy 以长达 36 天的生命史刷新全球记录，其极端性对热带气旋生成理论及预报提出了新的挑战。

**核心科学问题**：

* 四种热带波动（MJO、Kelvin、ER、MRG）在 Freddy 生成过程中各自扮演了什么角色？
* 热带波动如何通过涡旋拉伸机制促进初始涡旋的发展？
* 不同尺度波动的协同作用如何影响热带气旋生成的时间和位置？

> \*\*Freddy 生成区精确定义\*\*：南印度洋 \*\*10°S\\-20°S, 110°E\\-120°E\*\*（基于代码实际实现）
> 
> \*\*研究时间范围\*\*：\*\*2023 年 1 月 1 日 \\- 2023 年 3 月 31 日\*\*
> 
> \*\*Freddy 生成时间\*\*：\*\*2023 年 2 月 6 日\*\*
> 
> 

### 1.2 研究内容与技术路线图

本研究采用**时空滤波**技术从观测数据中分离不同尺度的热带波动信号，结合**动力诊断**方法分析涡旋拉伸和对流激发机制。

```mermaid
graph TD
    A\[原始数据获取] --> B\[数据预处理]
    B --> C\[气候态计算与去除]
    C --> D\[异常场计算]
    D --> E\[Wheeler-Kiladis波数-频率滤波]
    E --> F1\[MJO信号提取]
    E --> F2\[Kelvin波信号提取]
    E --> F3\[ER波信号提取]
    E --> F4\[MRG波信号提取]
    F1 \& F2 \& F3 \& F4 --> G\[动力诊断分析]
    G --> H\[VIMD水汽辐合诊断]
    G --> I\[涡旋拉伸项诊断]
    H \& I --> J\[结果可视化]
    J --> K\[波动贡献定量评估]```

\*\*主要技术路线\*\*：

1. \*\*数据预处理\*\*：计算 15 年气候态，使用傅里叶拟合去除年循环，得到异常场

2. \*\*波动分离\*\*：使用 NCL 的`kf\\\_filter`函数进行 Wheeler\\-Kiladis 波数 \\- 频率滤波

3. \*\*动力诊断\*\*：计算 VIMD（垂直积分水汽辐合）和涡旋拉伸项

4. \*\*统计分析\*\*：量化各波动的相对贡献

5. \*\*可视化\*\*：生成 Hovmöller 图、空间分布图、时间序列图

### 1\\.3 GitHub 仓库文件结构总览

```Plain Text
TC-Freddy-Tropical-Waves/
├── GPM\_precipitation/              # GPM降水数据处理
│   ├── 6hourly/                    # 6小时分辨率处理
│   │   ├── GPM\_6hourly\_Cumulative\_Precipitation.m
│   │   ├── calculate\_GPM\_anomaly\_6hourly.m
│   │   ├── plot\_precip\_6hourly\_freddy\_box.m
│   │   ├── plot\_precip\_hovmuller\_6hourly.m
│   │   └── \*.ncl                   # 4种波动滤波脚本
│   └── daily/                      # 日分辨率处理
│       ├── calculate\_GPM\_precipitation\_anomaly\_daily.m
│       ├── plot\_\*\_hovmoller\_diagram.m
│       └── \*.ncl                   # 4种波动滤波脚本
├── ERA5\_uv/                        # ERA5风场数据处理
│   ├── 6hourly/
│   │   ├── calculate\_uv\_anomaly\_6hourly.m
│   │   ├── plot\_u\_anomaly\_6hourly\_freddy\_box.m
│   │   └── \*.ncl
│   └── daily/
│       ├── transfer\_uv\_3hourly\_to\_daily.m
│       ├── calculate\_ERA5\_u\_v\_anomaly\_daily.m
│       ├── plot\_precip\_uv\_\*.m      # 4种波动的降水+风场图
│       ├── plot\_u\_anomaly\_daily\_freddy\_box.m
│       └── \*.ncl
├── ERA5\_VIMD/                      # 垂直积分水汽辐合
│   ├── calculate\_VIMD\_6hourly.m
│   ├── calculate\_VIMD\_anomaly\_6hourly.m
│   ├── plot\_vimd\_freddy\_box.m
│   └── \*.ncl                       # 4种波动滤波脚本
├── ERA5\_divergence/                # 散度与涡旋拉伸
│   ├── calculate\_divergence\_anomaly\_6hourly.m
│   ├── plot\_div\_vortex\_stretching\_\*.m  # 4种波动
│   ├── plot\_vortex\_stretching\_3D\_\*.m   # 4种波动3D图
│   └── \*.ncl
├── ERA5\_relative\_humidity/         # 相对湿度分析
│   └── plot\_q\_freddy\_box.m
├── OLR/                            # 射出长波辐射
│   ├── calculate\_OLR\_anomaly\_daily.m
│   ├── plot\_olr\_freddy\_box.m
│   └── plot\_olr\_\*.m                # 4种波动
├── Python\_codes/                   # Python辅助脚本
│   ├── Freddy\_\&\_Dingani\_Tracks\_(2023).py
│   ├── Monthly\_Mean\_Vertical\_Wind\_Shear.py
│   ├── mean\_specific\_humidity\_at\_850 \_Pa.py
│   ├── sst\_with\_full\_track.py
│   └── wind\_and\_precipitation.py
├── LICENSE
├── README.md
└── REPRODUCTION\_GUIDE.md           # 本文档
```

### 1.4 复现预期结果说明

成功复现本研究应获得以下结果：

|验证项|预期结果|容差范围|
|-|-|-|
|MJO 贡献占比|\~40%|±5%|
|Kelvin 波贡献|\~30%|±5%|
|ER 波贡献|\~15%|±3%|
|MRG 波贡献|\~15%|±3%|
|涡旋拉伸峰值时间|2023-02-05 ± 2 天|±3 天|
|VIMD 辐合峰值|2023-02-04 ± 1 天|±2 天|

> 💡 \*\*验证方法\*\*：对比生成的 Hovmöller 图中波动传播方向和速度，检查时间序列的峰值是否与 Freddy 生成时间对应。
> 
> 

\---

## 2\. 数据获取与准备

### 2.1 数据源详细信息表

|数据名称|时间范围|空间范围|时间分辨率|空间分辨率|变量列表|下载链接|下载方式|
|-|-|-|-|-|-|-|-|
|**GPM IMERG**|2009-2023|90°S-90°N, 180°W-180°E|30 分钟|0.1°×0.1°|precipitation|[NASA GES DISC](https://disc.gsfc.nasa.gov/datasets/GPM_3IMERGHH_07/)|wget / Python 脚本|
|**ERA5**|2009-2023|10°N-30°S, 0°-360°E|6 小时|0.25°×0.25°|u, v, q, d, vo, r|[ECMWF CDS](https://cds.climate.copernicus.eu)|CDS API / Python|
|**NOAA OLR**|2009-2023|90°S-90°N, 0°-360°E|日平均|1.0°×1.0°|olr|[NOAA NCEI](https://www.ncei.noaa.gov/)|wget / FTP|
|**IBTrACS**|2023|全球|6 小时|-|lat, lon, wind, pressure|[NOAA NCEI](https://www.ncei.noaa.gov/products/international-best-track-archive)|直接下载|

### 2.2 GPM IMERG 降水数据详细下载步骤

**官方网站**：[https://disc.gsfc.nasa.gov/datasets/GPM\_3IMERGHH\_07/](https://disc.gsfc.nasa.gov/datasets/GPM_3IMERGHH_07/)

**前置要求**：

* 注册 NASA Earthdata 账号
* 配置`\\.netrc`文件进行身份验证

#### 下载方法 1：使用 wget 批量下载

```bash
# 配置Earthdata身份验证
echo "machine urs.earthdata.nasa.gov login YOUR\_USERNAME password YOUR\_PASSWORD" > \~/.netrc
chmod 0600 \~/.netrc

# 批量下载2023年1-3月的数据
for year in 2023; do
    for month in 01 02 03; do
        for day in $(seq -w 1 31); do
            doy=$(date -d "$year-$month-$day" +%j 2>/dev/null)
            if \[ $? -eq 0 ]; then
                wget --load-cookies \~/.urs\_cookies --save-cookies \~/.urs\_cookies \\
                     --keep-session-cookies --no-check-certificate --auth-no-challenge=on \\
                     -r -np -nd -A "\*.HDF5" \\
                     "https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM\_L3/GPM\_3IMERGHH.07/$year/$doy/"
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
session.auth = ('YOUR\_USERNAME', 'YOUR\_PASSWORD')

base\_url = "https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM\_L3/GPM\_3IMERGHH.07"
output\_dir = "./data/GPM/30min/"
os.makedirs(output\_dir, exist\_ok=True)

# 下载2023年1-3月
start\_date = datetime(2023, 1, 1)
end\_date = datetime(2023, 3, 31)

current\_date = start\_date
while current\_date <= end\_date:
    year = current\_date.year
    doy = current\_date.timetuple().tm\_yday
    url = f"{base\_url}/{year}/{doy:03d}/"
    
    print(f"下载: {year}-{current\_date.month:02d}-{current\_date.day:02d} (DOY: {doy})")
    
    # 此处添加具体文件下载逻辑
    current\_date += timedelta(days=1)
```

> ⚠️ \*\*注意\*\*：GPM IMERG 数据量很大，2023 年 1\\-3 月约有 \*\*4320 个 HDF5 文件\*\*，总计约 \*\*50GB\*\*。建议使用多线程下载工具如`aria2`加速。
> 
> 

### 2.3 ERA5 再分析数据详细下载步骤

**官方网站**：[https://cds.climate.copernicus.eu/](https://cds.climate.copernicus.eu/)

**前置要求**：

* 注册 CDS 账号
* 安装`cdsapi` Python 库
* 配置`\\\~/\\.cdsapirc`文件

#### 安装 CDS API

```bash
pip install cdsapi

# 配置API密钥
echo "url: https://cds.climate.copernicus.eu/api/v2
key: YOUR\_UID:YOUR\_API\_KEY" > \~/.cdsapirc
```

#### 下载脚本：u/v 风场数据

```python
import cdsapi

c = cdsapi.Client()

# 下载850hPa和200hPa的u/v风场数据
c.retrieve(
    'reanalysis-era5-pressure-levels',
    {
        'product\_type': 'reanalysis',
        'variable': \['u\_component\_of\_wind', 'v\_component\_of\_wind'],
        'pressure\_level': \['850', '200'],
        'year': \['2009', '2010', '2011', '2012', '2013', '2014', '2015',
                 '2016', '2017', '2018', '2019', '2020', '2021', '2022', '2023'],
        'month': \['01', '02', '03', '04', '05', '06',
                  '07', '08', '09', '10', '11', '12'],
        'day': \[f'{i:02d}' for i in range(1, 32)],
        'time': \['00:00', '06:00', '12:00', '18:00'],
        'area': \['10', '0', '-30', '360'],  # N, W, S, E
        'format': 'netcdf',
    },
    'ERA5\_uv\_2009-2023.nc'
)
```

#### 下载脚本：比湿、散度、涡度数据

```python
import cdsapi

c = cdsapi.Client()

# 下载所有气压层的比湿、散度、相对涡度
pressure\_levels = \['1000', '975', '950', '925', '900', '875', '850', '825', '800',
                   '775', '750', '700', '650', '600', '550', '500', '450', '400',
                   '350', '300', '250', '225', '200', '175', '150', '125', '100']

c.retrieve(
    'reanalysis-era5-pressure-levels',
    {
        'product\_type': 'reanalysis',
        'variable': \['specific\_humidity', 'divergence', 'vorticity', 'relative\_humidity'],
        'pressure\_level': pressure\_levels,
        'year': \['2023'],
        'month': \['01', '02', '03'],
        'day': \[f'{i:02d}' for i in range(1, 32)],
        'time': \['00:00', '06:00', '12:00', '18:00'],
        'area': \['10', '0', '-30', '360'],
        'format': 'netcdf',
    },
    'ERA5\_q\_dv\_vo\_2023.nc'
)
```

> ⏱️ \*\*预计耗时\*\*：ERA5 数据下载约需 \*\*2\\-3 小时\*\*，取决于网络速度。建议分月份下载以避免请求超时。
> 
> 

### 2.4 NOAA OLR 射出长波辐射数据下载

**官方网站**：[https://www.esrl.noaa.gov/psd/](https://www.esrl.noaa.gov/psd/)

```bash
# 方法1：直接下载日平均OLR数据（推荐）
wget ftp://ftp.cdc.noaa.gov/Datasets/interp\_OLR/olr.day.mean.nc

# 方法2：分年度下载
for year in {2009..2023}; do
    wget "https://downloads.psl.noaa.gov/Datasets/interp\_OLR/olr-daily\_v01r02\_${year}0101\_${year}1231.nc"
done
```

### 2.5 IBTrACS 台风最佳路径数据下载

**官方网站**：[https://www.ncei.noaa.gov/products/international-best-track-archive](https://www.ncei.noaa.gov/products/international-best-track-archive)

```bash
# 南印度洋区域数据
wget "https://www.ncei.noaa.gov/data/international-best-track-archive-for-climate-stewardship-ibtracs/v04r01/access/netcdf/IBTrACS.SI.v04r01.nc"

# 或下载全球数据
wget "https://www.ncei.noaa.gov/data/international-best-track-archive-for-climate-stewardship-ibtracs/v04r01/access/netcdf/IBTrACS.ALL.v04r01.nc"
```

### 2.6 推荐的数据目录结构

```Plain Text
data/
├── GPM/
│   ├── 30min/              # 原始30分钟HDF5文件
│   │   └── 3B-HHR.MS.MRG.3IMERG.\*.HDF5
│   ├── 6hourly/            # 处理后的6小时累积
│   │   └── GPM\_6hourly\_\*.nc
│   └── daily/              # 日累积数据文件
│       └── GPM\_daily\_\*.nc
├── ERA5/
│   ├── uv/                 # u/v风场数据
│   │   ├── 200901\_uv.nc
│   │   ├── 200902\_uv.nc
│   │   └── ...
│   ├── q/                  # 比湿数据
│   │   ├── 200901\_q.nc
│   │   └── ...
│   ├── dv/                 # 散度数据
│   │   ├── 200901\_dv.nc
│   │   └── ...
│   └── VIMD/               # VIMD计算结果
│       ├── 200901\_VIMD.nc
│       └── ...
├── OLR/
│   ├── olr-daily\_v01r02\_20090101\_20091231.nc
│   ├── olr-daily\_v01r02\_20100101\_20101231.nc
│   └── ...
└── IBTrACS/
    └── IBTrACS.SI.v04r01.nc
```

### 2.7 数据完整性检查方法

#### 检查脚本示例

```matlab
% GPM数据完整性检查
data\_dir = './data/GPM/30min/';
start\_date = datetime(2023,1,1);
end\_date = datetime(2023,3,31);
expected\_files = 0;
actual\_files = 0;

current\_date = start\_date;
while current\_date <= end\_date
    % 每天应有48个30分钟文件
    expected\_files = expected\_files + 48;
    
    % 检查实际文件数量
    files = dir(fullfile(data\_dir, \['\*', datestr(current\_date, 'yyyymmdd'), '\*.HDF5']));
    actual\_files = actual\_files + length(files);
    
    current\_date = current\_date + days(1);
end

fprintf('GPM数据完整性检查:\\n');
fprintf('  预期文件数: %d\\n', expected\_files);
fprintf('  实际文件数: %d\\n', actual\_files);
fprintf('  完整度: %.2f%%\\n', 100\*actual\_files/expected\_files);

if actual\_files < expected\_files
    warning('GPM数据不完整，缺少 %d 个文件!', expected\_files - actual\_files);
end
```

> 💡 \*\*实用技巧\*\*：使用`ncdump \\-h filename\\.nc`快速检查 NetCDF 文件的维度和变量信息，确保数据格式正确。
> 
> 

\---

## 3\. 软件环境要求

### 3.1 MATLAB 版本要求与工具箱依赖

|软件|版本要求|用途|
|-|-|-|
|MATLAB|R2020a 或更高|数据预处理、异常值计算、结果分析、绘图|

**必需工具箱**：

* **Parallel Computing Toolbox**（可选，用于加速 FFT 计算）
* **Mapping Toolbox**（可选，用于地图绘制）
* **Statistics and Machine Learning Toolbox**（用于统计分析）

**验证 MATLAB 环境**：

```matlab
% 检查MATLAB版本
fprintf('MATLAB版本: %s\\n', version);

% 检查工具箱
required\_toolboxes = {'Parallel Computing Toolbox', 'Mapping Toolbox'};
for i = 1:length(required\_toolboxes)
    if license('test', required\_toolboxes{i})
        fprintf('✓ %s: 已安装\\n', required\_toolboxes{i});
    else
        fprintf('⚠ %s: 未安装（可选）\\n', required\_toolboxes{i});
    end
end
```

### 3.2 Python 版本要求与依赖库列表

|软件|版本要求|用途|
|-|-|-|
|Python|3.8+|数据下载、背景分析图绘制|

**完整依赖库列表**：

|库名|版本要求|用途|
|-|-|-|
|numpy|\&gt;=1.21.0|数值计算|
|pandas|\&gt;=1.3.0|数据处理|
|xarray|\&gt;=0.19.0|NetCDF 数据处理|
|netCDF4|\&gt;=1.5.7|NetCDF 文件读写|
|scipy|\&gt;=1.7.0|科学计算、FFT|
|cartopy|\&gt;=0.20.0|地图投影|
|matplotlib|\&gt;=3.4.0|数据可视化|
|metpy|\&gt;=1.2.0|气象计算|
|cdsapi|\&gt;=0.5.1|ERA5 数据下载|
|tqdm|\&gt;=4.62.0|进度条显示|

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

### 3.3 NCL 环境配置（用于波数 - 频率滤波）

|软件|版本要求|用途|
|-|-|-|
|NCL|6.6.2 或更高|Wheeler-Kiladis 波数 - 频率滤波|

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
load "$NCARG\_ROOT/lib/ncarg/nclscripts/contrib/kf\_filter.ncl"
load "$NCARG\_ROOT/lib/ncarg/nclscripts/contrib/time\_axis\_labels.ncl"
load "$NCARG\_ROOT/lib/ncarg/nclscripts/contrib/cd\_string.ncl"
load "$NCARG\_ROOT/lib/ncarg/nclscripts/contrib/ut\_string.ncl"
```

> ⚠️ \*\*重要\*\*：`kf\\\_filter\\.ncl`是 Wheeler\\-Kiladis 滤波的核心函数，必须确保该文件在 NCL 的搜索路径中。
> 
> 

### 3.4 环境验证脚本与测试方法

创建环境验证脚本 `test\\\_environment\\.ncl`：

```ncl
begin
    print("=== NCL环境验证 ===")
    
    ; 检查kf\_filter函数是否可用
    if (isdefined("kf\_filter")) then
        print("✓ kf\_filter函数: 可用")
    else
        print("✗ kf\_filter函数: 不可用")
        print("  请检查kf\_filter.ncl是否正确加载")
    end if
    
    ; 测试简单的滤波操作
    test\_data = random\_uniform(-1, 1, (/100, 360/))
    obsPerDay = 1
    tMin = 10
    tMax = 30
    kMin = 1
    kMax = 5
    hMin = 8
    hMax = 90
    waveName = "Kelvin"
    
    result = kf\_filter(test\_data, obsPerDay, tMin, tMax, kMin, kMax, hMin, hMax, waveName)
    
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
ncl test\_environment.ncl
```

### 3.5 硬件配置建议

|组件|最低配置|推荐配置|说明|
|-|-|-|-|
|**CPU**|4 核心|8 核心以上|并行计算加速 FFT 和滤波|
|**内存**|16GB|32GB 以上|处理大尺度气象数据|
|**存储**|100GB SSD|500GB SSD|存储原始数据和中间结果|
|**网络**|10Mbps|100Mbps 以上|快速下载气象数据|

> 💡 \*\*内存优化建议\*\*：处理 15 年的 6 小时数据时，建议使用 \*\*32GB 以上内存\*\*。如内存不足，可分年度处理数据。
> 
> 

\---

## 4\. 数据预处理流程

### 4.1 预处理整体流程图

```mermaid
graph TD
    A\[原始数据] --> B\[时间聚合]
    B --> C\[30min→6hourly]
    B --> D\[3hourly→daily]
    C --> E\[气候态计算]
    D --> E
    E --> F\[15年日循环平均]
    F --> G\[傅里叶拟合平滑]
    G --> H\[保留前5阶谐波]
    H --> I\[异常场计算]
    I --> J\[原始场 - 拟合气候态]
    J --> K\[标准化处理]
    K --> L\[VIMD计算]
    K --> M\[散度计算]
    L --> N\[VIMD异常场]
    M --> O\[散度异常场]```

### 4\\.2 气候态计算与去除（傅里叶拟合方法）

\*\*数学原理\*\*：

对于长度为 N（N=365 或 1460）的年循环时间序列 x \\(t\\)，其傅里叶级数展开为：

$x(t) = a\_0 + \\sum\_{k=1}^{N/2} \[a\_k \\cos(2\\pi k t/N) + b\_k \\sin(2\\pi k t/N)]$

\*\*前三阶谐波滤波保留\*\*：

- k=0（直流分量，年平均）

- k=1（一阶谐波，周期 1 年）

- k=2（二阶谐波，周期半年）

- k=3（三阶谐波，周期 4 个月）

\*\*MATLAB 实现\*\*：

```matlab
function fit\_climatology = fourier\_fit(climatology, num\_harmonics)
    % 傅里叶拟合气候态
    % 输入: climatology - 原始气候态 (365, nlon, nlat)
    %       num\_harmonics - 保留的谐波数量
    % 输出: fit\_climatology - 拟合后的气候态
    
    \[n\_days, nlon, nlat] = size(climatology);
    fit\_climatology = zeros(size(climatology));
    
    for i = 1:nlon
        for j = 1:nlat
            % 提取单个格点的时间序列
            ts = squeeze(climatology(:, i, j));
            
            % FFT变换
            ts\_fft = fft(ts);
            
            % 保留前num\_harmonics+1个系数（直流+基频+...）
            ts\_fft(num\_harmonics+2:end-num\_harmonics) = 0;
            
            % 逆FFT
            ts\_fit = ifft(ts\_fft);
            
            fit\_climatology(:, i, j) = real(ts\_fit);
        end
    end
end
```

> 💡 \*\*物理意义\*\*：傅里叶拟合避免了简单日气候平均值导致的年内变化细节丢失，能更准确地刻画温度、降水等的季节变化。
> 
> 

### 4.3 异常场计算方法

**异常场计算公式**：

$\\text{Anomaly}(t) = \\text{Original}\_{\\text{norm}}(t) - \\text{Fit\_Climatology}(doy)$

**完整计算步骤**：

```matlab
% 步骤1：读取所有数据
all\_data = read\_all\_gpm\_6hourly();

% 步骤2：计算日循环气候态（每年同一天的平均值）
climatology = zeros(366, lon\_size, lat\_size);
for day = 1:366
    indices = get\_day\_of\_year\_indices(all\_data.time, day);
    climatology(day,:,:) = mean(all\_data.precip(:,:,indices), 3);
end

% 步骤3：傅里叶拟合（保留前5个谐波）
fit\_climatology = fourier\_fit(climatology, 5);

% 步骤4：计算异常场
anomaly = zeros(size(all\_data.precip));
for t = 1:size(all\_data.precip, 3)
    day\_of\_year = dayofyear(all\_data.time(t));
    anomaly(:,:,t) = all\_data.precip(:,:,t) - squeeze(fit\_climatology(day\_of\_year,:,:));
end

% 步骤5：标准化
mean\_precip = mean(anomaly, 3);
std\_precip = std(anomaly, 0, 3);
normalized\_precip = (anomaly - mean\_precip) ./ std\_precip;
```

> ⏱️ \*\*预计耗时\*\*：GPM 6 小时异常场计算约需 \*\*4\\-6 小时\*\*，取决于 CPU 性能。
> 
> 

### 4.4 VIMD（垂直积分水汽辐合）详细计算

**VIMD 数学定义**：

$\\text{VIMD} = -\\frac{1}{g} \\int\_{1000}^{100} \\nabla \\cdot (q\\mathbf{V}) dp$

其中：

* $g = 9.8 , \\text{m/s}^2$ 为重力加速度
* $q$ = 比湿
* $\\mathbf{V} = (u, v)$ = 风矢量
* $\\nabla \\cdot$ = 水平散度算子
* $dp$ = 气压层厚度

**球坐标系下的散度展开**：

$\\nabla \\cdot (q\\mathbf{V}) = \\frac{1}{a\\cos\\varphi}\\left\[ \\frac{\\partial(qu)}{\\partial\\lambda} + \\frac{\\partial(qv\\cos\\varphi)}{\\partial\\varphi} \\right]$

其中$a$为地球半径，$\\varphi$为纬度，$\\lambda$为经度。

**MATLAB 核心实现**：

```matlab
% 预计算常数
g = 9.8;           % 重力加速度 (m/s^2)
a = 6371000;       % 地球半径 (m)
p\_Pa = plev \* 100; % hPa转换为Pa

% 垂直积分权重（梯形积分法）
w = zeros(nlev, 1);
w(1) = (p\_Pa(1) - p\_Pa(2)) / 2;
for k = 2:nlev-1
    w(k) = (p\_Pa(k-1) - p\_Pa(k+1)) / 2;
end
w(nlev) = (p\_Pa(nlev-1) - p\_Pa(nlev)) / 2;

% 预计算纬度余弦
lat\_rad = deg2rad(lat);
cos\_lat\_2d = repmat(cos(lat\_rad)', nlon, 1);
inv\_a\_coslat = 1 ./ (a \* cos\_lat\_2d);

% 差分索引（循环边界条件）
i\_west = \[nlon, 1:nlon-1];
i\_east = \[2:nlon, 1];

% 逐层计算
for k = 1:nlev
    % 水汽通量
    qu = q\_k .\* u\_k;
    qv = q\_k .\* v\_k;
    qv\_cos = qv .\* cos\_lat\_2d;
    
    % 经度导数 ∂(qu)/∂λ
    dqu\_dlambda = (qu(i\_east, :) - qu(i\_west, :)) / (2 \* dlambda);
    
    % 纬度导数 ∂(qv cosφ)/∂φ
    dqvcos\_dphi = (qv\_cos(:, i\_south) - qv\_cos(:, i\_north)) / (2 \* dphi);
    
    % 水平散度
    div\_qV = (dqu\_dlambda + dqvcos\_dphi) .\* inv\_a\_coslat;
    
    % 垂直积分累加
    vimd\_t = vimd\_t + div\_qV \* w(k);
end

% 乘以-1/g得到VIMD
vimd\_t = -1/g \* vimd\_t;
```

**物理意义**：

* **VIMD \&gt; 0**：整层水汽辐合，有利于对流发展和降水
* **VIMD \&lt; 0**：整层水汽辐散，不利于对流发展

> ⏱️ \*\*预计耗时\*\*：VIMD 计算约需 \*\*8\\-12 小时\*\*（15 年数据），建议分月份处理。
> 
> 

### 4.5 涡旋拉伸项动力诊断计算

**涡旋拉伸项定义**：

$S = \\eta \\cdot (-\\nabla \\cdot \\mathbf{V}')$

其中：

* $\\eta = \\zeta + f$（绝对涡度）
* $\\zeta$：相对涡度（从 ERA5 变量`vo`直接获取）
* $f = 2\\Omega \\sin\\varphi$（行星涡度）
* $\\mathbf{V}'$：滤波后的风场异常
* 负号确保低层辐合（$\\nabla \\cdot \\mathbf{V}' < 0$）产生正贡献

**MATLAB 核心实现**：

```matlab
% 科氏参数
Omega = 7.2921e-5;  % 地球自转角速度 (rad/s)
f\_array = 2 \* Omega \* sin(deg2rad(lat));

% 计算绝对涡度: η = ζ + f
abs\_vorticity = vo\_box + repmat(reshape(f\_array, \[1, lat\_size, 1]), \[lon\_size, 1, time\_size]);

% 计算涡旋拉伸项: η × (-∇·V')
vortex\_stretching = abs\_vort\_mean .\* (-mjo\_div\_mean);
```

**物理意义**：
涡旋拉伸项来源于涡度方程的垂直拉伸项：
$\\frac{D\\zeta}{Dt} \\propto \\eta \\frac{\\partial w}{\\partial z}$

在低层大气中，根据连续性方程，辐合（$\\nabla \\cdot \\mathbf{V}' < 0$）意味着上升运动（$\\partial w/\\partial z > 0$），从而拉伸绝对涡度管、增强气旋性环流。

### 4.6 每个 MATLAB 预处理脚本详解

#### GPM\_6hourly\_Cumulative\_Precipitation.m

|项目|内容|
|-|-|
|**输入文件**|GPM IMERG 30 分钟 HDF5 文件|
|**输出文件**|`GPM\\\_6hourly\\\_YYYYMMDDHHMMSS\\\_YYYYMMDDHHMMSS\\.nc`|
|**关键参数**|时间窗口：6 小时|
|**核心逻辑**|12 个 30 分钟文件累加，降水率 ×0.5 小时转换为累积量|
|**预计耗时**|2-3 小时|

**代码片段**：

```matlab
precip\_6h = zeros(lon\_size, lat\_size);
for f = 1:length(files)
    data = read\_gpm\_file(files{f});
    precip\_6h = precip\_6h + data.precipitation \* 0.5;  % mm/h × h = mm
end
```

#### calculate\_GPM\_anomaly\_6hourly.m

|项目|内容|
|-|-|
|**输入文件**|GPM\\*6hourly\\*\*.nc（2009-2023 年）|
|**输出文件**|`GPM\\\_anomaly\\\_6hourly\\\_20220901\\\_20230630\\.nc`|
|**关键参数**|傅里叶谐波数：5，纬度范围：20°S-20°N|
|**核心逻辑**|15 年气候态计算→傅里叶拟合→异常场计算|
|**预计耗时**|4-6 小时|

#### calculate\_VIMD\_6hourly.m

|项目|内容|
|-|-|
|**输入文件**|ERA5 u/v/q 数据（27 个气压层）|
|**输出文件**|`YYYYMM\\\_VIMD\\.nc`（共 180 个文件）|
|**关键参数**|积分范围：1000-100 hPa|
|**核心逻辑**|逐层计算水汽通量散度→梯形法垂直积分|
|**预计耗时**|8-12 小时|

### 4.7 预处理结果验证方法

**验证步骤**：

```matlab
% 1. 检查异常场统计特性
fprintf('异常场统计:\\n');
fprintf('  均值: %.4e (应接近0)\\n', mean(anomaly(:), 'omitnan'));
fprintf('  标准差: %.4f\\n', std(anomaly(:), 'omitnan'));
fprintf('  最小值: %.4f\\n', min(anomaly(:), \[], 'omitnan'));
fprintf('  最大值: %.4f\\n', max(anomaly(:), \[], 'omitnan'));

% 2. 检查空间相关性
corr\_map = corr(squeeze(anomaly(1, :, :))');
fprintf('  空间平均相关系数: %.4f\\n', mean(corr\_map(:), 'omitnan'));

% 3. 可视化检查
figure;
subplot(1,2,1);
pcolor(lon, lat, squeeze(mean(climatology, 1))');
shading interp;
colorbar;
title('原始气候态');

subplot(1,2,2);
pcolor(lon, lat, squeeze(mean(fit\_climatology, 1))');
shading interp;
colorbar;
title('傅里叶拟合后气候态');
```

> ⚠️ \*\*常见问题\*\*：如果异常场均值显著偏离 0，说明气候态计算有误，需检查日循环计算是否正确。
> 
> 

\---

## 5\. 波数 - 频率滤波（Wheeler-Kiladis 方法）

### 5.1 Wheeler-Kiladis 滤波方法概述

Wheeler-Kiladis 波数 - 频率滤波基于线性浅水波理论，利用不同赤道波动的色散关系在波数 - 频率域中的独特分布进行信号分离。

**基本原理**：

1. 对时空数据进行二维傅里叶变换，得到波数 - 频率谱
2. 基于浅水方程的色散关系确定各波型在波数 - 频率域中的理论分布区域
3. 设计带通滤波器，仅保留目标波型对应的波数 - 频率范围
4. 逆向 FFT 重建时空域的滤波信号

**kf\_filter 函数调用格式**：

```ncl
filtered\_data = kf\_filter(
    data,        // 二维数组 (time × lon)
    obsPerDay,   // 每天观测次数
    tMin, tMax,  // 周期范围（天）
    kMin, kMax,  // 波数范围（正=东传，负=西传）
    hMin, hMax,  // 等效深度范围（米）
    waveName     // 波型名称
)
```

### 5.2 NCL 滤波环境配置

**环境变量设置**：

```bash
# 设置NCL路径
export NCARG\_ROOT=/path/to/ncl
export PATH=$NCARG\_ROOT/bin:$PATH
export NCARG\_LIB=$NCARG\_ROOT/lib

# 验证kf\_filter.ncl位置
find $NCARG\_ROOT -name "kf\_filter.ncl"
```

**通用 NCL 脚本模板**：

```ncl
load "$NCARG\_ROOT/lib/ncarg/nclscripts/contrib/kf\_filter.ncl"
load "$NCARG\_ROOT/lib/ncarg/nclscripts/contrib/time\_axis\_labels.ncl"
load "$NCARG\_ROOT/lib/ncarg/nclscripts/contrib/cd\_string.ncl"

begin
    ; 读取输入文件
    f = addfile("input\_file.nc", "r")
    data = f->variable\_name
    
    ; 设置维度和坐标
    data!0 = "time"
    data!1 = "lon"
    data!2 = "lat"
    
    ; 创建输出数组
    filtered = new(dimsizes(data), float)
    
    ; 对每个纬度进行滤波
    do i = 0, dimsizes(lat)-1
        data\_slice = data(time|:, lon|:, lat|i)
        filtered(:,:,i) = kf\_filter(data\_slice, obsPerDay, \\
                                    tMin, tMax, kMin, kMax, \\
                                    hMin, hMax, waveName)
    end do
    
    ; 保存结果
    outfile = "output\_file.nc"
    system("rm -f " + outfile)
    a = addfile(outfile, "c")
    a->filtered\_variable = filtered
end
```

### 5.3 MJO 滤波：参数设置、物理意义、输入输出

**MJO 滤波参数**：

|参数|值|物理意义|
|-|-|-|
|tMin|30 天|最小周期|
|tMax|96 天|最大周期|
|kMin|1|最小纬向波数|
|kMax|9|最大纬向波数|
|hMin|0.01 m|最小等效深度|
|hMax|120 m|最大等效深度|
|obsPerDay|4|6 小时数据，每天 4 个观测|
|传播方向|东传|波数为正|

**输入输出文件**：

|数据类型|输入文件|输出文件|
|-|-|-|
|GPM 6 小时|`GPM\\\_anomaly\\\_6hourly\\\_20220901\\\_20230630\\.nc`|`GPM\\\_anomaly\\\_6hourly\\\_for\\\_MJO\\\_20220901\\\_20230630\\.nc`|
|GPM 日|`GPM\\\_anomaly\\\_daily\\\_\\\*\\.nc`|`GPM\\\_anomaly\\\_daily\\\_for\\\_MJO\\\_\\\*\\.nc`|
|风场 6 小时|`u\\\_v\\\_anomaly\\\_6hourly\\\_\\\*\\.nc`|`u\\\_v\\\_anomaly\\\_6hourly\\\_for\\\_MJO\\\_\\\*\\.nc`|
|风场日|`u\\\_v\\\_anomaly\\\_daily\\\_\\\*\\.nc`|`u\\\_v\\\_anomaly\\\_daily\\\_for\\\_MJO\\\_\\\*\\.nc`|
|VIMD|`VIMD\\\_anomaly\\\_6hourly\\\_\\\*\\.nc`|`VIMD\\\_anomaly\\\_6hourly\\\_for\\\_MJO\\\_\\\*\\.nc`|
|散度|`divergence\\\_anomaly\\\_6hourly\\\_\\\*\\.nc`|`divergence\\\_anomaly\\\_6hourly\\\_for\\\_MJO\\\_\\\*\\.nc`|
|OLR|`olr\\\_anomaly\\\_daily\\\_\\\*\\.nc`|`olr\\\_anomaly\\\_daily\\\_for\\\_MJO\\\_\\\*\\.nc`|

**物理意义**：
MJO（Madden-Julian Oscillation）是热带大气中最显著的季节内振荡信号，周期 30-90 天，向东传播。它通过调制大尺度环流和对流环境，为热带气旋生成提供有利背景。

### 5.4 Kelvin 波滤波：参数设置、物理意义、输入输出

**Kelvin 波滤波参数**：

|参数|值|物理意义|
|-|-|-|
|tMin|2.5 天|最小周期|
|tMax|17.0 天|最大周期|
|kMin|1|最小纬向波数|
|kMax|14|最大纬向波数|
|hMin|8.0 m|最小等效深度|
|hMax|90.0 m|最大等效深度|
|obsPerDay|4|每天 4 个观测|
|传播方向|东传|波数为正|

**等效深度与相速度关系**：

$c = \\sqrt{gh}$

其中 $g = 9.8 , \\text{m/s}^2$，等效深度 h=8-90m 对应相速度约 8.9-29.7 m/s。

**物理意义**：
赤道 Kelvin 波是一种向东传播的重力波，只存在于赤道附近。它在对流层低层表现为气压场和风场的耦合扰动，能够触发和组织对流活动。

### 5.5 ER 波（赤道罗斯贝波）滤波：参数设置、物理意义、输入输出

**ER 波滤波参数**：

|参数|值|物理意义|
|-|-|-|
|tMin|9.7 天|最小周期|
|tMax|48.0 天|最大周期|
|kMin|-1|最小波数（向西传播）|
|kMax|-10|最大波数（向西传播）|
|hMin|5.0 m|最小等效深度|
|hMax|90.0 m|最大等效深度|
|obsPerDay|4|每天 4 个观测|
|传播方向|西传|波数为负|

**物理意义**：
赤道罗斯贝波（Equatorial Rossby waves）是向西传播的大尺度波动，周期较长（10-50 天）。它们通过涡度平流和能量频散影响热带气旋生成环境。

### 5.6 MRG 波（混合罗斯贝重力波）滤波：参数设置、物理意义、输入输出

**MRG 波滤波参数**：

|参数|值|物理意义|
|-|-|-|
|tMin|3.0 天|最小周期|
|tMax|20.0 天|最大周期|
|kMin|-1|最小波数（向西传播）|
|kMax|-10|最大波数（向西传播）|
|hMin|8.0 m|最小等效深度|
|hMax|90.0 m|最大等效深度|
|obsPerDay|4|每天 4 个观测|
|传播方向|西传|波数为负|

**物理意义**：
混合罗斯贝重力波（Mixed Rossby-Gravity waves）是一种介于罗斯贝波和惯性重力波之间的波动类型，周期 3-20 天，向西传播。它们在热带气旋生成中扮演重要的触发角色。

### 5.7 滤波参数对照表

|波型|周期范围（天）|波数范围|传播方向|等效深度（m）|典型相速度（m/s）|
|-|-|-|-|-|-|
|**MJO**|30-96|1-9|东传|0.01-120|可变|
|**Kelvin**|2.5-17|1-14|东传|8-90|8.9-29.7|
|**ER**|9.7-48|-1 至 - 10|西传|5-90|7.0-29.7|
|**MRG**|3-20|-1 至 - 10|西传|8-90|8.9-29.7|

### 5.8 滤波结果质量评估方法

**评估指标**：

```ncl
; 1. 能量保留率
original\_energy = sum(data^2)
filtered\_energy = sum(filtered\_data^2)
energy\_ratio = filtered\_energy / original\_energy

print("能量保留率: " + energy\_ratio)
print("  预期范围: 0.1-0.4")

; 2. 频谱分析
; 对滤波前后数据进行功率谱分析，验证滤波效果

; 3. 相关性检查
corr = cor(data, filtered\_data)
print("滤波前后相关系数: " + corr)
print("  预期范围: 0.3-0.7")
```

> ⏱️ \*\*预计耗时\*\*：单个变量的四种波动滤波约需 \*\*2\\-4 小时\*\*，全部 7 个变量的滤波总计约需 \*\*14\\-28 小时\*\*。
> 
> 

> 💡 \*\*实用技巧\*\*：滤波计算可以并行进行，建议同时运行多个 NCL 进程以节省时间。
> 
> 

\---

## 6\. 结果分析与绘图

### 6.1 论文图件索引表

|图号|图表名称|生成脚本|输入数据|输出文件名|
|-|-|-|-|-|
|Fig.1|Freddy \&amp; Dingani 路径图|`Freddy\\\_\\\&amp;\\\_Dingani\\\_Tracks\\\_\\(2023\\)\\.py`|IBTrACS 数据|`Freddy\\\_Dingani\\\_Tracks\\.png`|
|Fig.2|四种波动 Hovmöller 图|`plot\\\_\\\*\\\_hovmoller\\\_diagram\\.m`|滤波后降水数据|`\\\*\\\_Hovmoller\\\_Diagram\\.png`|
|Fig.3|降水与风场异常空间分布|`plot\\\_precip\\\_uv\\\_\\\*\\.m`|滤波后降水 + 风场数据|`precip\\\_uv\\\_\\\*\\.png`|
|Fig.4|Freddy 生成区 Hovmöller 图|`plot\\\_precip\\\_hovmuller\\\_6hourly\\.m`|GPM 6 小时异常数据|`Freddy\\\_Hovmoller\\\_Diagram\\.png`|
|Fig.5|各变量波动贡献分解|`plot\\\_\\\*\\\_freddy\\\_box\\.m`|区域平均时间序列|`\\\*\\\_freddy\\\_box\\.png`|
|Fig.6|海温与垂直风切变|`sst\\\_with\\\_full\\\_track\\.py`|ERA5 SST 数据|`SST\\\_with\\\_Tracks\\.png`|
|Fig.7|涡旋拉伸时间序列|`plot\\\_div\\\_vortex\\\_stretching\\\_\\\*\\.m`|散度 + 涡度数据|`vortex\\\_stretching\\\_\\\*\\.png`|
|Fig.8|相对湿度垂直剖面|`plot\\\_q\\\_freddy\\\_box\\.m`|ERA5 湿度数据|`RH\\\_vertical\\\_profile\\.png`|

### 6.2 Hovmöller 时空演变图绘制

**核心绘图逻辑**：

```matlab
% 定义研究区域
lon\_min = 80;
lon\_max = 180;
lat\_min = -20;
lat\_max = -10;
start\_time = datetime(2023, 1, 1);
end\_time = datetime(2023, 3, 31);

% 沿纬度方向平均
precip\_avg = squeeze(mean(precip\_region, 1, 'omitnan'));

% 创建图形
figure('Position', \[100, 100, 800, 800]);

% 绘制降水异常填色图
h = imagesc(lon\_region\_numeric, time\_region\_numeric, precip\_avg);
set(gca, 'YDir', 'normal');

% 自定义颜色映射：负值（浅蓝→白），正值（白→深红）
ncolors = 64;
neg\_ratio = 0.13;  % 负值部分占13%
pos\_ratio = 0.86;   % 正值部分占86%
white\_ratio = 0.01; % 白色区域占1%

% 生成颜色映射...
colormap(cmap);

% 绘制各波列的等值线
contour(X, T, mjo\_avg, \[0.5, 1, 1.5, 2], 'k-', 'LineWidth', 1.6);
contour(X, T, kelvin\_avg, \[0.5, 1, 1.5, 2], 'b-', 'LineWidth', 1.6);
contour(X, T, mrg\_avg, \[0.5, 1, 1.5, 2], 'g-', 'LineWidth', 1.6);
contour(X, T, er\_avg, \[0.5, 1, 1.5, 2], 'r-', 'LineWidth', 1.6);

% 标记Freddy生成位置（洋红色方框）
rectangle('Position', \[110, freddy\_gen\_time\_num-1, 10, 2], ...
    'EdgeColor', 'magenta', 'LineWidth', 2.5);
```

**物理意义**：
Hovmöller 图是诊断热带波动传播的关键工具。通过对生成纬度带（10°S-20°S）内的降水异常做经度平均，将三维数据压缩为二维，可以清晰展示不同波动的向东或向西传播特征。

### 6.3 降水与风场合成图绘制

**脚本**：`plot\\\_precip\\\_uv\\\_mjo\\.m`、`plot\\\_precip\\\_uv\\\_kelvin\\.m`、`plot\\\_precip\\\_uv\\\_mrg\\.m`、`plot\\\_precip\\\_uv\\\_er\\.m`

**核心绘图逻辑**：

```matlab
% 输入：滤波后的降水异常和风场异常数据
% 输出：10张日合成图（2023-02-01至2023-02-10）

% 降水数据采用自定义暖色系填色
contourf(lon, lat, squeeze(precip(:,:,t))', 20, 'LineStyle', 'none');
colormap(hot\_colormap);
caxis(\[0, 10]);

% 风场数据用黑色箭头绘制
hold on;
quiver(lon(1:wind\_skip:end), lat(1:wind\_skip:end), ...
       u(1:wind\_skip:end, 1:wind\_skip:end, t)', ...
       v(1:wind\_skip:end, 1:wind\_skip:end, t)', ...
       0.5, 'k');

% 叠加海岸线和赤道线
load coast;
plot(long, lat, 'k', 'LineWidth', 0.5);
yline(0, 'k--', 'LineWidth', 0.8);
```

### 6.4 时间序列贡献分解图绘制

**通用逻辑**：

```matlab
% Freddy生成区：110°E-120°E, 10°S-20°S
box\_lon = \[110, 120];
box\_lat = \[-20, -10];

% 区域平均
box\_idx = find(lon >= box\_lon(1) \& lon <= box\_lon(2) \& ...
               lat >= box\_lat(1) \& lat <= box\_lat(2));

% 计算各波动的相对贡献
total\_var = var(original\_data(box\_idx, :));
mjo\_var = var(MJO\_data(box\_idx, :));
mrg\_var = var(MRG\_data(box\_idx, :));
er\_var = var(ER\_data(box\_idx, :));
kelvin\_var = var(Kelvin\_data(box\_idx, :));

contribution = \[mjo\_var, mrg\_var, er\_var, kelvin\_var] / total\_var \* 100;

% 绘图
plot(time, original, 'k--', 'LineWidth', 1.5);
hold on;
plot(time, mjo\_component, 'b-', 'LineWidth', 1.5);
plot(time, kelvin\_component, 'r-', 'LineWidth', 1.5);
plot(time, mrg\_component, 'g-', 'LineWidth', 1.5);
plot(time, er\_component, 'm-', 'LineWidth', 1.5);
plot(time, sum\_component, 'k-', 'LineWidth', 2);
```

### 6.5 涡旋拉伸三维图绘制

**脚本**：`plot\\\_vortex\\\_stretching\\\_3D\\\_\\\*\\.m`

**核心绘图逻辑**：

```matlab
% 坐标系统：X=经度(100°-130°E)，Y=纬度(25°S-5°S)，Z=涡旋拉伸项
% 视角：view(\[-35, 15])（西南方向俯视）

% 计算步骤：
% 1. 提取850hPa相对涡度
% 2. 计算绝对涡度：η = ζ + f
% 3. 提取散度异常
% 4. 计算涡旋拉伸项：η × (-divergence)

% 三维表面图
surf(lon, lat, vortex\_stretching \* 1e9);
shading interp;
colormap(blue\_white\_red\_colormap);
alpha(0.7);

% z\_min平面上绘制海岸线、Freddy位置、Genesis Box
hold on;
plot3(coast\_lon, coast\_lat, z\_min\*ones(size(coast\_lon)), 'k', 'LineWidth', 0.5);
plot3(freddy\_lon, freddy\_lat, z\_min, 'ro', 'MarkerSize', 10);
```

### 6.6 图形美化参数设置

**颜色设置**：

```matlab
% 自定义红蓝颜色映射（异常场）
function cmap = redblue\_colormap(n)
    if nargin < 1, n = 64; end
    cmap = zeros(n, 3);
    half = floor(n/2);
    
    % 蓝色部分（负值）
    for i = 1:half
        ratio = (i-1)/(half-1);
        cmap(i, :) = \[0.2 + 0.8\*ratio, 0.3 + 0.7\*ratio, 1.0];
    end
    
    % 红色部分（正值）
    for i = half+1:n
        ratio = (i-half-1)/(n-half-1);
        cmap(i, :) = \[1.0, 0.6 - 0.6\*ratio, 0.4 - 0.4\*ratio];
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

\---

## 7\. Python 辅助脚本详解

### 7.1 Python 脚本索引表

|脚本名称|功能|输入文件|输出文件|
|-|-|-|-|
|`Freddy\\\_\\\&amp;\\\_Dingani\\\_Tracks\\\_\\(2023\\)\\.py`|绘制 TC 路径轨迹|\[IBTrACS.SI.v04r01.nc](IBTrACS.SI.v04r01.nc)|`Freddy\\\_Dingani\\\_Tracks\\.png`|
|`Monthly\\\_Mean\\\_Vertical\\\_Wind\\\_Shear\\.py`|计算垂直风切变|ERA5 uv 数据|`Vertical\\\_Wind\\\_Shear\\.png`|
|`mean\\\_specific\\\_humidity\\\_at\\\_850 \\\_Pa\\.py`|绘制 850hPa 比湿|ERA5 q 数据|`Specific\\\_Humidity\\\_850hPa\\.png`|
|`sst\\\_with\\\_full\\\_track\\.py`|海温与路径叠加|ERA5 SST + IBTrACS|`SST\\\_with\\\_Tracks\\.png`|
|`wind\\\_and\\\_precipitation\\.py`|风场与降水合成|ERA5 uv + GPM|`Wind\\\_Precipitation\\.png`|

### 7.2 热带气旋路径绘制脚本详解

**脚本**：`Freddy\\\_\\\&amp;\\\_Dingani\\\_Tracks\\\_\\(2023\\)\\.py`

```python
import xarray as xr
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import numpy as np

def find\_storm\_index(dataset, target\_sid):
    """在IBTrACS数据中查找特定风暴的索引"""
    sids = dataset\['sid'].values
    for i, sid in enumerate(sids):
        if sid == target\_sid:
            return i
    return None

def extract\_track(dataset, idx):
    """提取风暴路径数据"""
    time = dataset\['time']\[idx].values
    lat = dataset\['lat']\[idx].values
    lon = dataset\['lon']\[idx].values
    valid = (lat > -90) \& (lon > -180) \& (\~np.isnat(time))
    return time\[valid], lat\[valid], lon\[valid]

# 主程序
ds = xr.open\_dataset("IBTrACS.SI.v04r01.nc")
freddy\_sid = b'2023036S12117'  # Freddy: 2023年第36天, 南纬12°, 东经117°

freddy\_idx = find\_storm\_index(ds, freddy\_sid)
freddy\_time, freddy\_lat, freddy\_lon = extract\_track(ds, freddy\_idx)

# 绘图
fig = plt.figure(figsize=(10, 8))
ax = plt.axes(projection=ccrs.PlateCarree())
ax.coastlines()
ax.gridlines(draw\_labels=True)

ax.plot(freddy\_lon, freddy\_lat, 'r-', linewidth=2, transform=ccrs.PlateCarree())
ax.scatter(freddy\_lon\[::4], freddy\_lat\[::4], c='red', s=50, transform=ccrs.PlateCarree())

plt.savefig('Freddy\_Track.png', dpi=300, bbox\_inches='tight')
```

**执行命令**：

```bash
python Freddy\_\\\&\_Dingani\_Tracks\_\\(2023\\).py
```

### 7.3 垂直风切变计算脚本详解

**脚本**：`Monthly\\\_Mean\\\_Vertical\\\_Wind\\\_Shear\\.py`

**核心计算**：

```python
def calculate\_vertical\_shear(ds):
    """
    计算200-850hPa垂直风切变
    
    数学原理:
        VWS = √\[(u200 - u850)² + (v200 - v850)²]
    
    物理意义:
        VWS < 10 m/s: 有利于发展
        VWS > 12 m/s: 抑制发展
    """
    u200 = ds\['u'].sel(pressure\_level=200, method='nearest')
    v200 = ds\['v'].sel(pressure\_level=200, method='nearest')
    u850 = ds\['u'].sel(pressure\_level=850, method='nearest')
    v850 = ds\['v'].sel(pressure\_level=850, method='nearest')
    return np.sqrt((u200 - u850)\*\*2 + (v200 - v850)\*\*2)
```

### 7.4 海温与路径叠加脚本详解

**关键技术点**：

```python
def get\_sst\_data(ds):
    """
    提取海表面温度数据
    
    单位转换:
        ERA5温度单位为K，转换为°C需减273.15
        使用1000hPa温度近似代表SST
    """
    sst = ds\['t'].sel(pressure\_level=1000, method='nearest') - 273.15
    return sst

# 使用patheffects实现路径的白边描边
import matplotlib.patheffects as pe
path\_effects = \[pe.Stroke(linewidth=3, foreground='white'), pe.Normal()]
ax.plot(track\_lon, track\_lat, 'r-', linewidth=2, path\_effects=path\_effects)
```

\---

## 8\. 完整代码运行顺序

### 8.1 整体运行流程图

```mermaid
graph TD
    A\[环境配置与验证] --> B\[数据下载与完整性检查]
    B --> C\[GPM数据预处理]
    B --> D\[ERA5数据预处理]
    B --> E\[OLR数据预处理]
    C --> F\[GPM异常场计算]
    D --> G\[风场异常场计算]
    D --> H\[VIMD计算]
    H --> I\[VIMD异常场计算]
    D --> J\[散度异常场计算]
    E --> K\[OLR异常场计算]
    F \& G \& I \& J \& K --> L\[波数-频率滤波]
    L --> M\[MJO滤波]
    L --> N\[Kelvin波滤波]
    L --> O\[ER波滤波]
    L --> P\[MRG波滤波]
    M \& N \& O \& P --> Q\[结果分析与绘图]
    Q --> R\[Hovmöller图]
    Q --> S\[空间分布图]
    Q --> T\[时间序列图]
    Q --> U\[涡旋拉伸诊断]```

### 8\\.2 第一步：环境配置与验证

⏱️ \*\*预计耗时\*\*：30 分钟

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

### 8.3 第二步：数据下载与完整性检查

⏱️ **预计耗时**：8-12 小时

```bash
# 1. 下载GPM数据（约50GB）
# 使用第2章提供的wget或Python脚本

# 2. 下载ERA5数据
python download\_era5.py

# 3. 下载OLR和IBTrACS数据
wget ftp://ftp.cdc.noaa.gov/Datasets/interp\_OLR/olr.day.mean.nc
wget "https://www.ncei.noaa.gov/data/international-best-track-archive-for-climate-stewardship-ibtracs/v04r01/access/netcdf/IBTrACS.SI.v04r01.nc"

# 4. 运行数据完整性检查脚本
matlab -nodisplay -r "check\_data\_integrity; exit;"
```

### 8.4 第三步：数据预处理

⏱️ **预计耗时**：24-36 小时

```matlab
% ===== GPM数据处理 =====
% 30分钟→6小时聚合
run('GPM\_precipitation/6hourly/GPM\_6hourly\_Cumulative\_Precipitation.m')
% ⏱️ 预计耗时：2-3小时

% 计算异常场
run('GPM\_precipitation/6hourly/calculate\_GPM\_anomaly\_6hourly.m')
% ⏱️ 预计耗时：4-6小时

% 日数据处理
run('GPM\_precipitation/daily/calculate\_GPM\_precipitation\_anomaly\_daily.m')
% ⏱️ 预计耗时：3-5小时

% ===== ERA5数据处理 =====
% 3小时→日平均
run('ERA5\_uv/daily/transfer\_uv\_3hourly\_to\_daily.m')
% ⏱️ 预计耗时：1-2小时

% 日异常场计算
run('ERA5\_uv/daily/calculate\_ERA5\_u\_v\_anomaly\_daily.m')
% ⏱️ 预计耗时：2-3小时

% 6小时异常场计算
run('ERA5\_uv/6hourly/calculate\_uv\_anomaly\_6hourly.m')
% ⏱️ 预计耗时：2-3小时

% VIMD计算
run('ERA5\_VIMD/calculate\_VIMD\_6hourly.m')
% ⏱️ 预计耗时：8-12小时
% 💡 建议内存：32GB以上

run('ERA5\_VIMD/calculate\_VIMD\_anomaly\_6hourly.m')
% ⏱️ 预计耗时：2-3小时

% 散度计算
run('ERA5\_divergence/calculate\_divergence\_anomaly\_6hourly.m')
% ⏱️ 预计耗时：2-3小时

% ===== OLR数据处理 =====
run('OLR/calculate\_OLR\_anomaly\_daily.m')
% ⏱️ 预计耗时：1-2小时
```

> 💡 \*\*内存管理建议\*\*：处理 VIMD 计算时，建议分月份处理，每处理完一个月后清理内存。
> 
> 

### 8.5 第四步：波数 - 频率滤波

⏱️ **预计耗时**：14-28 小时

```bash
# GPM降水波动分离
cd GPM\_precipitation/6hourly
ncl GPM\_anomaly\_for\_MJO\_6hourly\_20220901\_20230630.ncl
ncl GPM\_anomaly\_for\_Kelvin\_6hourly\_20220901\_20230630.ncl
ncl GPM\_anomaly\_for\_ER\_6hourly\_20220901\_20230630.ncl
ncl GPM\_anomaly\_for\_MRG\_6hourly\_20220901\_20230630.ncl
# ⏱️ 预计耗时：2-4小时
# 💡 建议内存：16GB以上

cd ../daily
ncl GPM\_anomaly\_daily\_for\_MJO\_\*.ncl
ncl GPM\_anomaly\_daily\_for\_Kelvin\_\*.ncl
ncl GPM\_anomaly\_daily\_for\_ER\_\*.ncl
ncl GPM\_anomaly\_daily\_for\_MRG\_\*.ncl

# 风场波动分离
cd ../../ERA5\_uv/6hourly
ncl u\_v\_anomaly\_for\_MJO\_\*.ncl
ncl u\_v\_anomaly\_for\_Kelvin\_\*.ncl
ncl u\_v\_anomaly\_for\_ER\_\*.ncl
ncl u\_v\_anomaly\_for\_MRG\_\*.ncl

cd ../daily
ncl u\_v\_anomaly\_for\_MJO\_daily\_\*.ncl
ncl u\_v\_anomaly\_for\_Kelvin\_daily\_\*.ncl
ncl u\_v\_anomaly\_for\_ER\_daily\_\*.ncl
ncl u\_v\_anomaly\_for\_MRG\_daily\_\*.ncl

# VIMD波动分离
cd ../../ERA5\_VIMD
ncl VIMD\_anomaly\_for\_MJO\_\*.ncl
ncl VIMD\_anomaly\_for\_Kelvin\_\*.ncl
ncl VIMD\_anomaly\_for\_ER\_\*.ncl
ncl VIMD\_anomaly\_for\_MRG\_\*.ncl

# 散度波动分离
cd ../ERA5\_divergence
ncl divergence\_anomaly\_for\_MJO\_\*.ncl
ncl divergence\_anomaly\_for\_Kelvin\_\*.ncl
ncl divergence\_anomaly\_for\_ER\_\*.ncl
ncl divergence\_anomaly\_for\_MRG\_\*.ncl

# OLR波动分离
cd ../OLR
ncl olr\_anomaly\_for\_MJO\_\*.ncl
ncl olr\_anomaly\_for\_Kelvin\_\*.ncl
ncl olr\_anomaly\_for\_ER\_\*.ncl
ncl olr\_anomaly\_for\_MRG\_\*.ncl
```

> 💡 \*\*并行处理建议\*\*：可以同时运行 4 个 NCL 进程（MJO、Kelvin、ER、MRG）以节省时间。
> 
> 

### 8.6 第五步：结果分析与绘图

⏱️ **预计耗时**：4-8 小时

```bash
# Python图表生成
cd Python\_codes
python Freddy\_\\\&\_Dingani\_Tracks\_\\(2023\\).py
python mean\_specific\_humidity\_at\_850\\ \_Pa.py
python Monthly\_Mean\_Vertical\_Wind\_Shear.py
python sst\_with\_full\_track.py
python wind\_and\_precipitation.py

# MATLAB图表生成
# 运行所有plot\_\*.m脚本
```

### 8.7 路径配置文件修改说明

**修改所有 MATLAB 脚本中的数据路径**：

```matlab
% 原始路径（作者本地路径）
input\_path = 'E:\\Original\_Data\_of\_Freddy\\ERA5\_dv\_q\_uv\_200901\_202312\_every\_6hours';
output\_path = 'E:\\Results\_of\_Freddy\\VIMD\_200901\_202312\_every\_6hours';

% 修改为您的本地路径
input\_path = '/your/path/to/data/ERA5/';
output\_path = '/your/path/to/results/VIMD/';
```

> ⚠️ \*\*重要\*\*：所有脚本中的路径都是绝对路径，必须根据您的实际环境进行修改！
> 
> 

### 8.8 内存管理与大文件处理建议

**内存优化技巧**：

```matlab
% 1. 使用single精度代替double
data = single(data);  % 内存占用减半

% 2. 及时清理不需要的变量
clear large\_variable;

% 3. 分块处理大文件
for block = 1:num\_blocks
    data\_block = read\_block(block);
    process(data\_block);
    clear data\_block;
end

% 4. 增加MATLAB堆内存大小
java.lang.Runtime.getRuntime.maxMemory / 1e9  % 显示最大内存
```

### 8.9 常见运行错误与解决方案

|错误类型|可能原因|解决方案|
|-|-|-|
|**内存不足 (Out of Memory)**|数据量过大|分批次处理，使用 single 精度，增加系统内存|
|**NetCDF 读写错误**|路径包含中文或特殊字符|使用英文路径，检查文件完整性|
|**kf\_filter 返回全 NaN**|数据维度顺序错误|确保维度为 (time, lon, lat)|
|**滤波结果异常**|参数设置错误|检查 tMin/tMax/kMin/kMax 的取值范围|
|**NCL 找不到 kf\_filter**|contributed 脚本未正确安装|检查 $NCARG\_ROOT 路径设置|
|**傅里叶拟合出现复数**|FFT 处理不当|取实部：real (ifft (...))|

\---

## 9\. 附录：关键方法原理

### 9.1 Wheeler-Kiladis 波数 - 频率滤波数学原理详细推导

**时空傅里叶变换**：

对于时空场 $\\psi(\\lambda, t)$，其二维傅里叶变换为：

$\\Psi(k, \\omega) = \\frac{1}{2\\pi} \\int\_{-\\infty}^{\\infty} \\int\_{0}^{2\\pi} \\psi(\\lambda, t) e^{-i(k\\lambda - \\omega t)} d\\lambda dt$

其中：

* $k$ = 纬向波数
* $\\omega$ = 角频率

**线性浅水方程色散关系**：

对于赤道波动，线性浅水方程给出色散关系：

$\\omega^2 - c^2 k^2 = (2n+1) \\beta c$

其中：

* $c = \\sqrt{gh}$ = 重力波相速度
* $\\beta = df/dy$ = 科氏参数经向梯度
* $n$ = 经向模数

**不同波动的色散关系**：

|波型|n|色散关系|
|-|-|-|
|Kelvin|-1|$\\omega = ck$|
|MRG|0|$\\omega^2 = c^2 k^2 + \\beta c$|
|ER|n ≥ 1|$\\omega = -\\beta k / (k^2 + (2n+1)\\beta/c)$|

**滤波区域构建**：

在波数 - 频率平面上，根据上述色散关系定义每个波型的允许区域，仅保留该区域内的傅里叶系数，然后进行逆变换得到滤波后的时空场。

### 9.2 傅里叶拟合气候态计算方法

**傅里叶级数展开**：

$x(t) = \\frac{a\_0}{2} + \\sum\_{k=1}^{\\infty} \\left\[ a\_k \\cos\\left(\\frac{2\\pi k t}{T}\\right) + b\_k \\sin\\left(\\frac{2\\pi k t}{T}\\right) \\right]$

其中系数计算公式：

$a\_0 = \\frac{2}{T} \\int\_0^T x(t) dt$
$a\_k = \\frac{2}{T} \\int\_0^T x(t) \\cos\\left(\\frac{2\\pi k t}{T}\\right) dt$
$b\_k = \\frac{2}{T} \\int\_0^T x(t) \\sin\\left(\\frac{2\\pi k t}{T}\\right) dt$

**FFT 实现**：

在频域中，保留前 N+1 个傅里叶系数（直流分量 + N 个谐波），其余置零，然后逆 FFT 得到平滑的气候态。

### 9.3 涡度方程与涡旋拉伸项推导

**完整的涡度方程**：

$\\frac{D\\zeta}{Dt} = -(\\zeta + f) \\nabla \\cdot \\mathbf{V} - \\mathbf{V} \\cdot \\nabla f + \\left( \\frac{\\partial w}{\\partial y} \\frac{\\partial u}{\\partial z} - \\frac{\\partial w}{\\partial x} \\frac{\\partial v}{\\partial z} \\right) + \\frac{1}{\\rho^2} \\left( \\frac{\\partial \\rho}{\\partial x} \\frac{\\partial p}{\\partial y} - \\frac{\\partial \\rho}{\\partial y} \\frac{\\partial p}{\\partial x} \\right)$

**涡旋拉伸项**：

在热带气旋生成的早期阶段，涡旋拉伸项是最主要的涡度增长机制：

$\\frac{D\\zeta}{Dt} \\approx -(\\zeta + f) \\nabla \\cdot \\mathbf{V} = \\eta \\frac{\\partial w}{\\partial z}$

根据连续性方程：

$\\nabla \\cdot \\mathbf{V} = -\\frac{\\partial w}{\\partial z}$

因此：

$\\frac{D\\zeta}{Dt} \\approx \\eta \\frac{\\partial w}{\\partial z} = \\eta \\cdot (-\\nabla \\cdot \\mathbf{V})$

这就是本研究中使用的涡旋拉伸项诊断公式。

### 9.4 VIMD 物理意义与计算公式推导

**水汽通量散度**：

单位面积气柱内的水汽收支方程为：

$\\frac{\\partial}{\\partial t} \\int\_{p\_s}^{p\_t} q \\frac{dp}{g} = -\\int\_{p\_s}^{p\_t} \\nabla \\cdot (q\\mathbf{V}) \\frac{dp}{g} + (E - P)$

其中：

* 左边 = 气柱内水汽的局地变化
* 右边第一项 = 水汽通量的水平辐合
* 右边第二项 = 表面蒸发减降水

**VIMD 定义**：

垂直积分的水汽通量辐合（VIMD）定义为：

$\\text{VIMD} = -\\frac{1}{g} \\int\_{p\_s}^{p\_t} \\nabla \\cdot (q\\mathbf{V}) dp$

VIMD 的正值表示水汽辐合，是对流发展和降水发生的必要条件。

### 9.5 波动能量诊断方法

**波动动能**：

$K' = \\frac{1}{2} (u'^2 + v'^2)$

**波动有效位能**：

$A' = \\frac{g^2}{2N^2} \\left( \\frac{\\theta'}{\\bar{\\theta}} \\right)^2$

**能量转换项**：

$C(A', K') = -\\frac{g}{\\bar{\\theta}} \\overline{w' \\theta'}$

### 9.6 参考文献列表

1. Wheeler, M. and G.N. Kiladis (1999). Convectively coupled equatorial waves: Analysis of clouds and temperature in the wavenumber-frequency domain. *Journal of the Atmospheric Sciences*, 56, 374-399.
2. Kiladis, G.N., et al. (2005). A comparison of the MJO and convectively coupled equatorial waves during TOGA COARE. *Journal of the Atmospheric Sciences*, 62, 2762-2779.
3. Matsuno, T. (1966). Quasi-geostrophic motions in the equatorial area. *Journal of the Meteorological Society of Japan*, 44, 25-43.
4. Huffman, G.J., et al. (2019). GPM IMERG Final Precipitation L3 Half Hourly 0.1 degree x 0.1 degree V06.
5. Hersbach, H., et al. (2020). The ERA5 global reanalysis. *Quarterly Journal of the Royal Meteorological Society*.
6. Liebmann, B. and C.A. Smith (1996). Description of a complete (interpolated) outgoing longwave radiation dataset. *Bulletin of the American Meteorological Society*, 77, 1275-1277.
7. Knapp, K.R., et al. (2010). International Best Track Archive for Climate Stewardship (IBTrACS): Unifying tropical cyclone best track data. *Bulletin of the American Meteorological Society*, 91, 363-376.

### 9.7 常见问题 FAQ

**Q: 为什么我的滤波结果全是 NaN？**
A: 检查数据维度顺序是否为 (time, lon, lat)，kf\_filter 函数对维度顺序很敏感。

**Q: VIMD 计算结果的符号为什么与预期相反？**
A: VIMD 定义中包含负号，正值表示辐合。请检查公式中的 - 1/g 因子。

**Q: 为什么需要 15 年的数据来计算气候态？**
A: 足够长的时间序列可以更准确地估计年循环，减少年际变率的影响。

**Q: 可以只处理 2023 年的数据吗？**
A: 不行。异常场计算需要 15 年的基期数据来计算气候态。

**Q: 内存不足怎么办？**
A: 分年度处理，使用 single 精度，及时清理不需要的变量。

\---

**技术支持**：如有问题，请在 GitHub 仓库提交 Issue。

**许可证**：MIT License

> （注：文档部分内容可能由 AI 生成）

