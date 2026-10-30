
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    CASE 
        WHEN cd_demo_sk IS NOT NULL THEN cd_gender
        ELSE 'N/A' 
    END AS gender,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_sales_price) AS average_order_value,
    DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_city IS NOT NULL 
    AND ca.ca_state IN ('NY', 'CA', 'TX')
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd_demo_sk, cd_gender
HAVING 
    COUNT(ws.ws_order_number) > 0
ORDER BY 
    total_sales DESC, full_name;
