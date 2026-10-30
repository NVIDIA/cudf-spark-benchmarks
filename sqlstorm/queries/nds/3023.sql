
WITH SalesData AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_ship_customer_sk) AS unique_customers,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_order_number, 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        ws_item_sk,
        total_net_profit,
        unique_customers
    FROM 
        SalesData
    WHERE 
        profit_rank <= 5
)
SELECT 
    si.i_item_id,
    si.i_item_desc,
    COALESCE(tsi.total_net_profit, 0) AS total_net_profit,
    COALESCE(tsi.unique_customers, 0) AS unique_customers,
    CASE
        WHEN tsi.total_net_profit IS NULL THEN 'No sales'
        WHEN tsi.total_net_profit > 1000 THEN 'High Performer'
        ELSE 'Moderate Performer'
    END AS performance_category
FROM 
    item si
LEFT JOIN 
    TopSellingItems tsi ON si.i_item_sk = tsi.ws_item_sk
WHERE 
    si.i_current_price IS NOT NULL
ORDER BY 
    total_net_profit DESC NULLS LAST;
