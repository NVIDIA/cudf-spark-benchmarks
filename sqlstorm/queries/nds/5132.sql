
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    SUM(ws.ws_quantity) AS total_quantity_sold, 
    SUM(ws.ws_sales_price) AS total_sales, 
    MAX(ws.ws_sold_date_sk) AS last_purchase_date,
    CONCAT(ca.ca_city, ', ', ca.ca_state) AS address,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    CASE 
        WHEN SUM(ws.ws_sales_price) > 10000 THEN 'High Value'
        WHEN SUM(ws.ws_sales_price) BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_segment
FROM 
    customer c 
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231 
GROUP BY 
    c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, 
    ca.ca_city, ca.ca_state
HAVING 
    SUM(ws.ws_quantity) > 50
ORDER BY 
    total_sales DESC;
