WITH  SalesCTE AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451549 
    GROUP BY ws.ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id, 
        item.i_item_desc,
        sales.total_sales
    FROM SalesCTE sales
    JOIN item ON sales.ws_item_sk = item.i_item_sk
    WHERE sales.rank <= 10
    ORDER BY sales.total_sales DESC
),
ShippingDetails AS (
    SELECT 
        sm.sm_ship_mode_id,
        sm.sm_type,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_ship_cost) AS total_ship_cost
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id, sm.sm_type
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_sales,
    sd.sm_ship_mode_id,
    sd.sm_type,
    sd.order_count,
    sd.total_ship_cost,
    coalesce(d.d_year, 0) AS year,
    coalesce(d.d_month_seq, 0) AS month_seq
FROM TopItems ti
LEFT JOIN ShippingDetails sd ON ti.total_sales > sd.total_ship_cost
LEFT JOIN date_dim d ON d.d_date_sk IN (2451545, 2451546, 2451547) 
WHERE ti.total_sales IS NOT NULL
ORDER BY ti.total_sales DESC, sd.total_ship_cost DESC;