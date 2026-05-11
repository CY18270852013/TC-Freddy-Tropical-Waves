import xarray as xr
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import numpy as np
from datetime import datetime, timedelta

# 读取IBTrACS数据
ds = xr.open_dataset(r"D:\Freddy_ChenYong\Data\IBTrACS.SI.v04r01.nc")

# 定义目标sid
freddy_sid = b'2023036S12117'
dingani_sid = b'2023032S12091'

# 查找目标风暴的索引
def find_storm_index(dataset, target_sid):
    sids = dataset['sid'].values
    for i, sid in enumerate(sids):
        if sid == target_sid:
            return i
    return None

freddy_idx = find_storm_index(ds, freddy_sid)
dingani_idx = find_storm_index(ds, dingani_sid)

# 提取数据
def extract_track(dataset, idx):
    time = dataset['time'][idx].values
    lat = dataset['lat'][idx].values
    lon = dataset['lon'][idx].values
    valid = (lat > -90) & (lon > -180) & (~np.isnat(time))
    return time[valid], lat[valid], lon[valid]

freddy_time, freddy_lat, freddy_lon = extract_track(ds, freddy_idx)
dingani_time, dingani_lat, dingani_lon = extract_track(ds, dingani_idx)

# 创建地图
plt.figure(figsize=(12, 8))
ax = plt.axes(projection=ccrs.PlateCarree())
ax.add_feature(cfeature.LAND, facecolor='lightgray')
ax.add_feature(cfeature.COASTLINE, linewidth=0.5)
ax.add_feature(cfeature.OCEAN, facecolor='white')
ax.gridlines(draw_labels=True, linestyle='--', alpha=0.5)
ax.set_extent([30, 120, 0, -40], crs=ccrs.PlateCarree())

# 绘制轨迹线
freddy_line, = ax.plot(freddy_lon, freddy_lat, color='red', linewidth=2, label='Freddy', zorder=2)
dingani_line, = ax.plot(dingani_lon, dingani_lat, color='blue', linestyle='--', linewidth=2, label='Dingani', zorder=2)

# 改进的日期标注函数（含标记点）
def add_date_labels(time_array, lon_array, lat_array, ax, color):
    last_label_date = None
    label_offset = 0.8  # 经纬度偏移量
    
    for t, x, y in zip(time_array, lon_array, lat_array):
        try:
            if isinstance(t, np.datetime64):
                py_time = t.astype('datetime64[s]').item()
                
                # 标注条件：UTC12点 + 间隔两天
                if py_time.hour == 12 and py_time.minute == 0:
                    current_date = py_time.date()
                    
                    if last_label_date is None or (current_date - last_label_date).days >= 2:
                        # 绘制黑色标记点（使用原始坐标）
                        ax.scatter(x, y, color='black', s=15, zorder=3,  # 点大小30，层级3
                                  transform=ccrs.PlateCarree())
                        
                        # 文字标注（偏移显示）
                        offset = label_offset * (1 if (current_date.day % 2) else -1)
                        ax.text(x + 0.3, y + offset,
                                current_date.strftime('%m%d'),
                                color=color, fontsize=9, 
                                ha='center', va='bottom' if offset > 0 else 'top',
                                transform=ccrs.PlateCarree(),
                                bbox=dict(facecolor='white', alpha=0.7, 
                                        edgecolor='none', pad=0.5))
                        last_label_date = current_date
        except Exception as e:
            print(f"跳过异常数据点: {str(e)}")
            continue

add_date_labels(freddy_time, freddy_lon, freddy_lat, ax, 'red')
add_date_labels(dingani_time, dingani_lon, dingani_lat, ax, 'blue')

# 添加图例（需包含新标记）
from matplotlib.lines import Line2D
legend_elements = [
    Line2D([0], [0], color='red', lw=2, label='Freddy'),
    Line2D([0], [0], color='blue', lw=2, linestyle='--', label='Dingani'),
    Line2D([0], [0], marker='o', color='black', lw=0,
          markerfacecolor='black', markersize=6, label='Date Marker')
]
plt.legend(handles=legend_elements, loc='lower left')

plt.title('Tropical Cyclones Freddy & Dingani Tracks (2023)', fontsize=14, pad=20)
plt.savefig('final_tropical_cyclone_tracks.png', dpi=300, bbox_inches='tight')
plt.show()