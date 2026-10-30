
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        i.i_item_id,
        rs.total_sales,
        rs.total_orders,
        COUNT(sr_return_quantity) AS total_returns
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        store_returns sr ON rs.ws_item_sk = sr.sr_item_sk
    WHERE 
        rs.rank <= 10
    GROUP BY 
        i.i_item_id, rs.total_sales, rs.total_orders
)
SELECT 
    tsi.i_item_id,
    tsi.total_sales,
    tsi.total_orders,
    tsi.total_returns,
    (tsi.total_sales - COALESCE(tsi.total_returns * i.i_current_price, 0)) AS net_profit
FROM 
    TopSellingItems tsi
JOIN 
    item i ON tsi.i_item_id = i.i_item_id
ORDER BY 
    net_profit DESC;
