import os
print(os.path.dirname(__file__), 1, os.getcwd(), 1, __file__)
dir_root=os.getcwd()+ ("/"+os.path.dirname(__file__) if os.path.dirname(__file__)!="" else "")
output_dir=f"{dir_root}/../tmp"
print(dir_root, output_dir)