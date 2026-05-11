# -*- coding: utf-8 -*-
"""
Created on Sat May  3 22:41:59 2025

@author: Dell
"""

import xarray as xr
import numpy as np
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import os
from datetime import datetime, timedelta
from matplotlib.colors import LinearSegmentedColormap

colors = [
    '#FFFFFF',  # 0 mm (白)
    '#D4EBFF',  # 1-10 mm (极浅蓝)
    '#99CCFF',  # 10-20 mm (浅蓝)
    '#66B2FF',  # 20-30 mm (中等蓝)
    '#3399FF',  # 30-40 mm (标准蓝)
    '#0066CC'   # 40-50 mm (深蓝)
]
cmap_enhanced = LinearSegmentedColormap.from_list('enhanced_blue', colors, N=256)

# 设置绘图参数
plt.rcParams['font.family'] = 'Arial'
plt.rcParams['font.size'] = 12

# 定义地图范围（根据Freddy活动区域调整）
lon_range = [80, 150]  # 南印度洋典型区域
lat_range = [-30, 10]

# 加载ERA5数据
era5_path = r"D:\Freddy_ChenYong\Data\ERA5_hourly_data_on_850hPa_20230101_20230331_Divergence_Relativehumidity_U_V.nc"
ds_era5 = xr.open_dataset(era5_path)

# 处理ERA5数据
# 筛选850 hPa数据，转换经度到-180-180范围
ds_era5 = ds_era5.sel(pressure_level=850.0)
ds_era5 = ds_era5.assign_coords(longitude=(((ds_era5.longitude + 180) % 360) - 180))
ds_era5 = ds_era5.sortby('longitude')

# 计算日平均风场
daily_u = ds_era5['u'].resample(valid_time='1D').mean()
daily_v = ds_era5['v'].resample(valid_time='1D').mean()

# 生成日期序列（2023-02-01到2023-02-10，每1天）
start_date = datetime(2023, 2, 1)
end_date = datetime(2023, 2, 10)
date_list = [start_date + timedelta(days=x) for x in range(0, (end_date-start_date).days+1, 1)]

# 创建输出目录
output_dir = r"D:\Freddy_ChenYong\Plot_ChenYong\Figures_Daily_Precipitation_and_850_hPa_Winds"
os.makedirs(output_dir, exist_ok=True)

# 循环处理每个日期
for target_date in date_list:
    # 处理ERA5数据
    era5_date = target_date.strftime("%Y-%m-%d")
    try:
        u_day = daily_u.sel(valid_time=era5_date)
        v_day = daily_v.sel(valid_time=era5_date)
    except KeyError:
        print(f"ERA5 data not found for {era5_date}")
        continue

    # 处理GPM数据
    gpm_file = f"3B-DAY.MS.MRG.3IMERG.{target_date.strftime('%Y%m%d')}-S000000-E235959.V07B.nc4"
    gpm_path = os.path.join(r"D:\Freddy_ChenYong\Data\GPM_3IMERGDF_07-20230201_20230331_daily", gpm_file)
    
    try:
        ds_gpm = xr.open_dataset(gpm_path)
        precip = ds_gpm['precipitation'][0].T  # 转置维度
    except FileNotFoundError:
        print(f"GPM file not found: {gpm_file}")
        continue

    # 创建绘图画布
    fig = plt.figure(figsize=(12, 8))
    ax = fig.add_subplot(1, 1, 1, projection=ccrs.PlateCarree())

    # 添加地理要素
    ax.add_feature(cfeature.LAND, facecolor='lightgray')
    ax.add_feature(cfeature.COASTLINE, linewidth=0.5)
    ax.add_feature(cfeature.BORDERS, linestyle=':', linewidth=0.5)
    gl = ax.gridlines(draw_labels=True, linestyle='--', alpha=0.5)
    gl.top_labels = False
    gl.right_labels = False

    # 绘制降水填色
    precip_plot = ax.pcolormesh(
        ds_gpm.lon, ds_gpm.lat, precip,
        cmap=cmap_enhanced,
        vmin=0, vmax=50,
        transform=ccrs.PlateCarree()
    )

    # 绘制风矢量（稀疏处理，每8个点取一个）
    skip = 8
    q = ax.quiver(
        u_day.longitude[::skip], 
        u_day.latitude[::skip],
        u_day.values[::skip, ::skip],
        v_day.values[::skip, ::skip],
        scale=300,
        color='k',
        transform=ccrs.PlateCarree()
    )

    # 添加矢量比例尺
    ax.quiverkey(q, X=0.85, Y=1.1, U=10, 
                label='10 m/s', labelpos='E')

    # 设置标题和范围
    ax.set_title(f"Daily Precipitation and 850 hPa Winds\n{target_date.strftime('%Y-%m-%d')}", pad=20)
    ax.set_extent([lon_range[0], lon_range[1], lat_range[0], lat_range[1]])
    ax.set_ylim(lat_range)

    # 添加色标
    cbar = plt.colorbar(precip_plot, ax=ax, shrink=0.8)
    cbar.set_label('Precipitation (mm/day)')

    # 保存图形
    output_path = os.path.join(output_dir, f"Freddy_{target_date.strftime('%Y%m%d')}.png")
    plt.savefig(output_path, dpi=500, bbox_inches='tight')
    plt.show()
    plt.close()

print("绘图完成！所有结果已保存至:", output_dir)

# 关闭数据集
ds_era5.close()