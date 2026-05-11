# -*- coding: utf-8 -*-
"""
Created on Mon May  5 03:33:11 2025

@author: Dell
"""

import xarray as xr
import numpy as np
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from matplotlib.colors import LinearSegmentedColormap
from matplotlib import patheffects

# ==============================
# 第一部分：处理ERA5海温数据
# ==============================
def get_sst_data(ds):
    """提取海表面温度数据"""
    sst = ds['t'].sel(pressure_level=1000, method='nearest') - 273.15  # 转换为摄氏度
    return sst

era5_ds = xr.open_dataset(r"D:\Freddy_ChenYong\Data\ERA5_monthly_averaged_data_on_pressure_levels.nc")
feb_sst = get_sst_data(era5_ds.sel(valid_time='2023-02')).squeeze()

# ==============================
# 第二部分：处理热带气旋路径数据
# ==============================
def extract_freddy_track(tc_ds, target_sid):
    sids = tc_ds['sid'].values
    for i, sid in enumerate(sids):
        if sid == target_sid:
            time = tc_ds['time'][i].values
            lat = tc_ds['lat'][i].values
            lon = tc_ds['lon'][i].values
            valid = (lat > -90) & (lon > -180) & (~np.isnat(time))
            return time[valid], lat[valid], lon[valid]
    return None, None, None

tc_ds = xr.open_dataset(r"D:\Freddy_ChenYong\Data\IBTrACS.SI.v04r01.nc")
freddy_sid = b'2023036S12117'
freddy_time, freddy_lat, freddy_lon = extract_freddy_track(tc_ds, freddy_sid)

# ==============================
# 第三部分：颜色映射设置
# ==============================
colors = [
    (0.0, '#000080'),   (1/12, '#0000FF'),
    (2/12, '#87CEEB'),   (3/12, '#ADD8E6'),
    (4/12, '#FFFFFF'),   (5/12, '#FFE4E1'),
    (6/12, '#FFB6C1'),   (7/12, '#FF69B4'),
    (8/12, '#FF0000'),   (9/12, '#CD0000'),
    (10/12, '#8B0000'),  (11/12, '#660000'),
    (1.0, '#400000')
]
cmap = LinearSegmentedColormap.from_list("sst_cmap", colors, N=256)
levels = np.arange(18, 31, 1)

# ==============================
# 第四部分：绘图设置（最终修改版）
# ==============================
def plot_sst_map():
    fig = plt.figure(figsize=(15, 10))
    ax = fig.add_subplot(1, 1, 1, projection=ccrs.PlateCarree())
    
    # 绘制海温填色图
    cf = feb_sst.plot.contourf(ax=ax, transform=ccrs.PlateCarree(),
                              cmap=cmap, levels=levels,
                              add_colorbar=False, extend='both',
                              antialiased=True)
    
    # 地理要素设置（陆地改为白色）
    ax.add_feature(cfeature.LAND, facecolor='white', zorder=1, edgecolor='none')  # 修改点1
    ax.add_feature(cfeature.COASTLINE, linewidth=0.8, zorder=2, edgecolor='gray')  # 添加海岸线颜色
    ax.add_feature(cfeature.OCEAN, facecolor='white', zorder=0)  # 海洋背景色
    ax.set_extent([30, 120, -40, 0], crs=ccrs.PlateCarree())
    
    # 网格线设置
    gl = ax.gridlines(draw_labels=True, linestyle='--', alpha=0.7,
                     xlocs=np.arange(30, 121, 15),
                     ylocs=np.arange(-40, 1, 5))
    
    # 绘制完整生命周期路径（移除时间筛选）  # 修改点2
    ax.plot(freddy_lon, freddy_lat,  # 使用全部有效数据
           color='black', linewidth=3, zorder=3,
           path_effects=[
               patheffects.Stroke(linewidth=4, foreground='white'),
               patheffects.Normal()])
    
    # 色标设置
    cbar = plt.colorbar(cf, orientation='horizontal', 
                       pad=0.08, aspect=40,
                       drawedges=True)
    cbar.set_label('Sea Surface Temperature (°C)', fontsize=14, labelpad=10)
    cbar.ax.tick_params(labelsize=12)
    
    # 标题设置
    plt.title('Monthly Mean Sea Surface Temperature (February 2023)',
             fontsize=16, pad=20, fontweight='bold')
    
    # 保存输出
    plt.savefig('sst_full_track.png', dpi=600, bbox_inches='tight', facecolor='white')
    plt.close()

# ==============================
# 执行绘图
# ==============================
plot_sst_map()