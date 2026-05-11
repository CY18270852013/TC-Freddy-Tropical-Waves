import xarray as xr
import numpy as np
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature

# 文件路径
file_path = r'D:\MATLAB\Freddy\ERA5_data\data_stream-oper.nc'

# 读取数据
ds = xr.open_dataset(file_path)

# 提取相关变量
q = ds['q']  # 比湿
lon = ds['longitude']  # 经度
lat = ds['latitude']  # 纬度
time = ds['valid_time']  # 时间

# 选择2023年2月3日至2023年3月14日之间的时间范围
time_selected = time.sel(valid_time=slice('2023-02-03', '2023-03-14'))

# 提取相应时间段的比湿数据
q_selected = q.sel(valid_time=time_selected)

# 计算850百帕高度层的比湿平均值
q_mean = q_selected.mean(dim='valid_time')

# 创建图形和地图投影
plt.figure(figsize=(12, 8))
ax = plt.axes(projection=ccrs.PlateCarree())

# 绘制热力图
c = ax.contourf(lon, lat, q_mean.squeeze(), levels=100, cmap='coolwarm', transform=ccrs.PlateCarree())

# 添加海岸线、国家边界和经纬度网格
ax.coastlines()
ax.add_feature(cfeature.BORDERS, linestyle=':')
ax.gridlines(draw_labels=True, linewidth=1, color='gray', alpha=0.5, linestyle='--')

# 添加颜色条
cb = plt.colorbar(c, ax=ax, orientation='vertical', pad=0.05)
cb.set_label('Specific Humidity (kg/kg)')

# 设置标题和轴标签
plt.title('Mean Specific Humidity (q) at 850 hPa (Feb 3 - Mar 14, 2023)', fontsize=15)
plt.xlabel('Longitude (°E)')
plt.ylabel('Latitude (°N)')

# 显示图形
plt.show()
