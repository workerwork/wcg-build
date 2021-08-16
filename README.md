## 2.1使用说明

### 替换修改rpmbuild/SOURCES/eGW-install中的文件

1)注意保持文件位置不变

2)需要执行权限的要手动添加执行权限

### 运行./make_rpm.sh -v x.x.x -r x

Usage:
    -v/--version 1.0.0(可选)
	-r/--release 1（可选）
    -b/--base(可选)    #制作基础版本包 
       --India(可选)   #制作印度版本包 

### 在rpmbuild路径下会生成rpm包

<注意>

如果生成的包不包含"centos"字样，可以修改/etc/rpm/macros.dist的"%dist"字段为"el7.centos"
