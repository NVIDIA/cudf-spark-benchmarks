
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_quantity) AS total_items_purchased,
    SUM(ws.ws_sales_price) AS total_spent,
    AVG(ws.ws_net_profit) AS avg_profit_per_item,
    d.d_year,
    d.d_month_seq,
    ca.ca_city,
    ca.ca_state,
    cd.cd_marital_status,
    cd.cd_gender
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    d.d_year BETWEEN 2022 AND 2023
GROUP BY 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d.d_year,
    d.d_month_seq,
    ca.ca_city,
    ca.ca_state,
    cd.cd_marital_status,
    cd.cd_gender
ORDER BY 
    total_spent DESC
LIMIT 100;
