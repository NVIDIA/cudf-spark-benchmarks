
WITH sales_data AS (
    SELECT
        ws_sold_date_sk,
        ws_ship_mode_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_ship_mode_sk
),
date_range AS (
    SELECT 
        d_date_sk, 
        d_year, 
        d_month_seq
    FROM date_dim 
    WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
summary AS (
    SELECT
        dr.d_year,
        dr.d_month_seq,
        sd.ws_ship_mode_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.avg_net_profit
    FROM sales_data sd
    JOIN date_range dr ON sd.ws_sold_date_sk = dr.d_date_sk
)
SELECT 
    d.d_year,
    d.d_month_seq,
    sm.sm_ship_mode_id,
    COALESCE(SUM(s.total_quantity), 0) AS total_quantity,
    COALESCE(SUM(s.total_sales), 0) AS total_sales,
    COALESCE(AVG(s.avg_net_profit), 0) AS avg_net_profit
FROM date_range d
CROSS JOIN ship_mode sm
LEFT JOIN summary s ON d.d_year = s.d_year 
                     AND d.d_month_seq = s.d_month_seq 
                     AND sm.sm_ship_mode_sk = s.ws_ship_mode_sk
GROUP BY 
    d.d_year, 
    d.d_month_seq, 
    sm.sm_ship_mode_id
ORDER BY 
    d.d_year, 
    d.d_month_seq, 
    sm.sm_ship_mode_id;
