WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2001
      AND dd.d_moy IN (11, 12)  
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
RankedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.order_count,
        RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM SalesData sd
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales,
        rs.order_count
    FROM RankedSales rs
    WHERE rs.sales_rank <= 10
)
SELECT 
    it.i_item_id,
    it.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.order_count,
    COALESCE(sm.sm_type, 'N/A') AS shipping_mode
FROM TopItems ti
JOIN item it ON ti.ws_item_sk = it.i_item_sk
LEFT JOIN ship_mode sm ON ti.order_count = sm.sm_ship_mode_sk
ORDER BY ti.total_sales DESC, ti.total_quantity DESC;