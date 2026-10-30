
WITH enriched_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_ship_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        d.d_day_name,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    d_year,
    d_month_seq,
    d_week_seq,
    d_day_name,
    cd_gender,
    COUNT(ws_order_number) AS total_orders,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_net_paid) AS total_revenue,
    AVG(ws_net_paid) AS avg_order_value
FROM 
    enriched_sales
WHERE 
    d_year = 2023
GROUP BY 
    d_year, d_month_seq, d_week_seq, d_day_name, cd_gender
ORDER BY 
    d_year, d_month_seq, d_week_seq, cd_gender;
