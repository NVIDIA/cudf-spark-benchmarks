
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_quantity,
        ci.c_current_cdemo_sk,
        ci.c_birth_month,
        ci.c_birth_year,
        dd.d_year,
        dd.d_month_seq,
        sm.sm_type
    FROM web_sales ws
    JOIN customer ci ON ws.ws_ship_customer_sk = ci.c_customer_sk
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE dd.d_year = 2023
    AND ci.c_birth_month = 5
    AND ci.c_birth_year BETWEEN 1980 AND 1995
),
AggregatedSales AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_quantity) AS total_quantity
    FROM SalesData
    GROUP BY ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    a.total_orders,
    a.total_sales,
    a.total_discount,
    a.total_quantity,
    (a.total_sales - a.total_discount) AS net_revenue
FROM AggregatedSales a
JOIN item i ON a.ws_item_sk = i.i_item_sk
ORDER BY net_revenue DESC
LIMIT 10;
