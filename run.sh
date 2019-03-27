docker run --runtime=nvidia --rm -it -p 9888:9888 -p 9787:9787 -p 9786:9786  -p 9800:9800 \
-v /raid/walmart/vibhu/wallmart_data:/rapids/wallmart_data \
-v /raid/walmart/vibhu/walmart_sparksql_joins:/rapids/walmart_sparksql_joins \
-e NVIDIA_VISIBLE_DEVICES=1,2,3,4,5,6,7 \
-it rapids
