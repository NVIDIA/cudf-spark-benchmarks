
WITH SalesData AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_ship_mode_sk,
        ws_net_paid,
        ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),

RankedSales AS (
    SELECT
        s.ws_sold_date_sk,
        s.ws_item_sk,
        s.ws_ship_mode_sk,
        s.ws_net_paid,
        s.ws_quantity,
        i.i_brand,
        sm.sm_type,
        DENSE_RANK() OVER (PARTITION BY s.ws_ship_mode_sk ORDER BY s.ws_net_paid DESC) AS shipment_rank
    FROM SalesData s
    JOIN item i ON s.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE s.sales_rank <= 5
)

SELECT 
    d.d_date AS sale_date,
    i.i_brand AS item_brand,
    sm.sm_type AS shipping_type,
    SUM(rs.ws_net_paid) AS total_sales,
    SUM(rs.ws_quantity) AS total_quantity,
    COUNT(DISTINCT rs.ws_item_sk) AS unique_items_sold
FROM RankedSales rs
JOIN date_dim d ON rs.ws_sold_date_sk = d.d_date_sk
JOIN item i ON rs.ws_item_sk = i.i_item_sk
JOIN ship_mode sm ON rs.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE d.d_year = 2022
GROUP BY d.d_date, i.i_brand, sm.sm_type
ORDER BY total_sales DESC
LIMIT 10;
