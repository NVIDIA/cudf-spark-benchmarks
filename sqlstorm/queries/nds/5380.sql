
SELECT 
    c.c_customer_id,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_paid) AS total_sales_amount,
    d.d_month_seq,
    d.d_year,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    MAX(ws.ws_sales_price) AS max_item_price,
    AVG(ws.ws_net_profit) AS average_net_profit
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    d.d_year BETWEEN 2021 AND 2023 
    AND cd.cd_gender = 'M'
GROUP BY 
    c.c_customer_id, d.d_month_seq, d.d_year
ORDER BY 
    total_sales_amount DESC, total_quantity_sold DESC
LIMIT 100;
