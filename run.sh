docker run --runtime=nvidia --rm -it -p 7888:7888 -p 7787:7787 -p 7786:7786  -p 7800:7800 \
-v /raid/walmart/vibhu/wallmart_data:/rapids/wallmart_data \
-v /raid/walmart/vibhu/walmart_sparksql_joins:/rapids/walmart_sparksql_joins \
-e NVIDIA_VISIBLE_DEVICES=1,2,3,4,5,6,7 \
-it rapids
