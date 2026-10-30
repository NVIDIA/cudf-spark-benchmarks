
SELECT c.c_first_name, c.c_last_name, cc.cc_name, ss.ss_sales_price 
FROM customer c 
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
JOIN call_center cc ON ss.ss_store_sk = cc.cc_call_center_sk 
WHERE cc.cc_state = 'CA' 
ORDER BY ss.ss_sales_price DESC 
LIMIT 10;
