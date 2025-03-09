import os
import requests
import shutil

# 字体文件URL（使用jsDelivr CDN）
FONTS = {
    'JetBrainsMono-Regular.ttf': 'https://cdn.jsdelivr.net/gh/JetBrains/JetBrainsMono@master/fonts/ttf/JetBrainsMono-Regular.ttf',
    'JetBrainsMono-Bold.ttf': 'https://cdn.jsdelivr.net/gh/JetBrains/JetBrainsMono@master/fonts/ttf/JetBrainsMono-Bold.ttf',
    'JetBrainsMono-Italic.ttf': 'https://cdn.jsdelivr.net/gh/JetBrains/JetBrainsMono@master/fonts/ttf/JetBrainsMono-Italic.ttf'
}

# 创建fonts目录
fonts_dir = '../assets/fonts'
os.makedirs(fonts_dir, exist_ok=True)

# 下载字体文件
for font_name, url in FONTS.items():
    font_path = os.path.join(fonts_dir, font_name)
    if not os.path.exists(font_path):
        print(f'Downloading {font_name}...')
        response = requests.get(url, stream=True)
        if response.status_code == 200:
            with open(font_path, 'wb') as f:
                shutil.copyfileobj(response.raw, f)
            print(f'Downloaded {font_name}')
        else:
            print(f'Failed to download {font_name}: {response.status_code}')
    else:
        print(f'{font_name} already exists') 