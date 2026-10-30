
SELECT c.c_customer_id, 
       ca.ca_city, 
       COUNT(DISTINCT ws.ws_order_number) AS total_orders,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       AVG(ws.ws_net_profit) AS average_profit
FROM customer AS c
JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE ca.ca_state = 'CA' 
  AND ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
GROUP BY c.c_customer_id, ca.ca_city
ORDER BY total_sales DESC
LIMIT 100;
