
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    CASE 
        WHEN COUNT(DISTINCT ws.ws_order_number) > 5 THEN 'Frequent Buyer'
        WHEN COUNT(DISTINCT ws.ws_order_number) BETWEEN 1 AND 5 THEN 'Occasional Buyer'
        ELSE 'No Orders'
    END AS buyer_segment,
    MAX(ws.ws_sold_date_sk) AS last_purchase_date
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    SUM(ws.ws_sales_price) > 1000
ORDER BY 
    total_spent DESC, last_purchase_date DESC
LIMIT 100;
