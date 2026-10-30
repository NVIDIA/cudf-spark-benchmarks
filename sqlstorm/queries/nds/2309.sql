
WITH RecentSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws_order_number) AS number_of_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),    
SalesThreshold AS (
    SELECT 
        ir.i_item_id,
        ir.i_current_price,
        rs.total_quantity_sold,
        rs.number_of_sales,
        rs.avg_net_profit,
        DENSE_RANK() OVER (ORDER BY rs.avg_net_profit DESC) AS rank
    FROM RecentSales rs
    JOIN item ir ON rs.ws_item_sk = ir.i_item_sk
    WHERE rs.total_quantity_sold > 100
)

SELECT 
    w.w_warehouse_id,
    w.w_warehouse_name,
    COALESCE(ST.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(ST.number_of_sales, 0) AS number_of_sales,
    COALESCE(ST.avg_net_profit, 0) AS avg_net_profit,
    CASE 
        WHEN ST.rank <= 10 THEN 'Top Selling'
        WHEN ST.rank <= 50 THEN 'Moderately Selling'
        ELSE 'Low Selling' 
    END AS sales_category
FROM warehouse w
LEFT JOIN SalesThreshold ST ON w.w_warehouse_id = ST.i_item_id
WHERE 
    w.w_warehouse_id LIKE 'W%'
ORDER BY w.w_warehouse_id ASC;
