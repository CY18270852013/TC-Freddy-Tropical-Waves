import xarray as xr
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from matplotlib.colors import LinearSegmentedColormap

# ==============================
# 新增：月份缩写到数字的映射字典
# ==============================
month_abbr_to_num = {
    'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
    'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
    'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12'
}

# ==============================
# 修改后的绘图函数（使用pandas处理日期）
# ==============================
def plot_shear_map(data, title, save_name):
    fig = plt.figure(figsize=(12, 8))
    ax = fig.add_subplot(1, 1, 1, projection=ccrs.PlateCarree())
    
    # 获取月份数字
    month_abbr = title[:3]
    month_num = month_abbr_to_num[month_abbr]
    
    # 使用pandas处理日期（关键修改部分）
    start_date = pd.Timestamp(f'2023-{month_num}-01')
    end_date = start_date + pd.DateOffset(months=1)  # 下个月第一天
    
    # 转换回numpy.datetime64类型（确保兼容性）
    start_date_np = start_date.to_numpy()
    end_date_np = end_date.to_numpy()
    
    # 筛选当月路径数据
    mask = (freddy_time >= start_date_np) & (freddy_time < end_date_np)
    
    # 绘制风切变
    cf = data.plot.contourf(ax=ax, transform=ccrs.PlateCarree(),
                           cmap=cmap, levels=levels,
                           add_colorbar=False, extend='both')
    
    # 地理要素（纬度范围改为南纬40°）
    ax.set_extent([30, 120, -40, 0], crs=ccrs.PlateCarree())
    ax.add_feature(cfeature.LAND, facecolor='lightgray')
    ax.add_feature(cfeature.COASTLINE, linewidth=0.8)
    ax.gridlines(draw_labels=True, linestyle='--', alpha=0.7)
    
    # 添加路径（使用筛选后的数据）
    ax.plot(freddy_lon[mask], freddy_lat[mask], 
           color='black', linewidth=2.5, transform=ccrs.PlateCarree())
    
    # 添加色标
    cbar = plt.colorbar(cf, orientation='horizontal', pad=0.05, aspect=50)
    cbar.set_label('Vertical Wind Shear (m s⁻¹)', fontsize=12)
    
    plt.title(f'Monthly Mean Vertical Wind Shear ({title})', fontsize=14, pad=15)
    plt.savefig(save_name, dpi=300, bbox_inches='tight')
    plt.close()

# ==============================
# 其他部分保持不变
# ==============================
def calculate_vertical_shear(ds):
    u200 = ds['u'].sel(pressure_level=200, method='nearest')
    v200 = ds['v'].sel(pressure_level=200, method='nearest')
    u850 = ds['u'].sel(pressure_level=850, method='nearest')
    v850 = ds['v'].sel(pressure_level=850, method='nearest')    
    return np.sqrt((u200 - u850)**2 + (v200 - v850)**2)

era5_ds = xr.open_dataset(r"D:\Freddy_ChenYong\Data\ERA5_monthly_averaged_data_on_pressure_levels.nc")
feb_shear = calculate_vertical_shear(era5_ds.sel(valid_time='2023-02')).squeeze()
mar_shear = calculate_vertical_shear(era5_ds.sel(valid_time='2023-03')).squeeze()

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

colors = [
    (0.0, '#000080'), (0.2, '#0000FF'),
    (0.4, '#87CEEB'), (0.5, '#FFFFFF'),
    (0.6, '#FFB6C1'), (0.8, '#FF0000'),
    (1.0, '#8B0000')
]
cmap = LinearSegmentedColormap.from_list("custom_div", colors)
levels = np.arange(0, 36, 2)

# ==============================
# 生成两张独立图片
# ==============================
plot_shear_map(feb_shear, 'February 2023', 'vertical_shear_feb.png')
plot_shear_map(mar_shear, 'March 2023', 'vertical_shear_mar.png')