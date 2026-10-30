
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ws.ws_net_paid_inc_tax) AS total_spent,
    COUNT(ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid_inc_tax) AS average_order_value,
    COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased,
    SUM(ws.ws_quantity) AS total_quantity,
    d.d_year
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    cd.cd_gender = 'F' 
    AND d.d_year = 2023 
    AND c.c_birth_year BETWEEN 1970 AND 1990
GROUP BY 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    d.d_year
HAVING 
    SUM(ws.ws_net_paid_inc_tax) > 1000
ORDER BY 
    total_spent DESC
LIMIT 100;
