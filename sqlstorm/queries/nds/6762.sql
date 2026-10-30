
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        c.c_birth_year,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        d.d_dow,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity,
        AVG(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS avg_sales_price
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2019 AND 2021
)

SELECT 
    sd.ws_item_sk,
    COUNT(DISTINCT sd.ws_order_number) AS order_count,
    SUM(sd.total_quantity) AS total_units_sold,
    SUM(sd.ws_net_paid) AS total_net_revenue,
    AVG(sd.avg_sales_price) AS average_sales_price,
    MIN(sd.d_year) AS first_year_sold,
    MAX(sd.d_year) AS last_year_sold,
    sd.cd_gender,
    COUNT(CASE WHEN sd.cd_marital_status = 'M' THEN 1 END) AS married_count,
    COUNT(CASE WHEN sd.cd_marital_status = 'S' THEN 1 END) AS single_count
FROM SalesData sd
GROUP BY sd.ws_item_sk, sd.cd_gender
ORDER BY total_net_revenue DESC
LIMIT 10;
