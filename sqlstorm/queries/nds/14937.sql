
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    SUM(ws_sales_price) AS total_sales,
    AVG(cd_purchase_estimate) AS average_purchase_estimate
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    ca_state
ORDER BY 
    customer_count DESC;
