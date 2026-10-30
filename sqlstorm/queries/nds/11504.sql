
SELECT ca_state, COUNT(DISTINCT c_customer_id) AS num_customers, SUM(ws_net_profit) AS total_net_profit
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE ca_state IN ('CA', 'TX', 'NY')
AND ws_sold_date_sk BETWEEN 2458480 AND 2458490
GROUP BY ca_state
ORDER BY total_net_profit DESC;
