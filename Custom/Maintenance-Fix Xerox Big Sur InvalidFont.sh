#!/bin/sh

cd /etc/cups/ppd
find ./ -type f -exec sed -i '' -e "s/TTRasterizer: None/TTRasterizer: Type42/" {} \;