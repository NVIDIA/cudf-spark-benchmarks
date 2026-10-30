
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_ship_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
AggregatedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(*) AS total_orders
    FROM
        web_sales ws
    WHERE
        ws.ws_ship_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        asales.ws_item_sk,
        asales.total_sales,
        asales.total_orders,
        RANK() OVER (ORDER BY asales.total_sales DESC) AS item_rank
    FROM 
        AggregatedSales asales
    WHERE 
        asales.total_orders > 10
)
SELECT 
    ci.i_item_id,
    ci.i_item_desc,
    ti.total_sales,
    ti.total_orders
FROM 
    TopItems ti
JOIN 
    item ci ON ti.ws_item_sk = ci.i_item_sk
LEFT JOIN 
    customer_demographics cd ON ci.i_item_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F'
    AND ti.item_rank <= 10
    AND ci.i_current_price IS NOT NULL
ORDER BY 
    ti.total_sales DESC;
