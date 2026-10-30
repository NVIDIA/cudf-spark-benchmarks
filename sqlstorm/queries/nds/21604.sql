
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(rs.total_quantity, 0) AS total_quantity,
        COALESCE(rs.total_profit, 0) AS total_profit
    FROM 
        item
    LEFT JOIN 
        RankedSales rs ON item.i_item_sk = rs.ws_item_sk
    WHERE 
        COALESCE(rs.total_profit, 0) > 0 
    ORDER BY 
        total_profit DESC
    LIMIT 10
),
WarehouseSummary AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ss.ss_item_sk) AS unique_items_sold,
        SUM(ss.ss_net_profit) AS total_sales_profit
    FROM 
        warehouse w
    LEFT JOIN 
        store_sales ss ON ss.ss_store_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
FinalAggregation AS (
    SELECT 
        ti.i_item_id,
        ti.i_item_desc,
        ws.w_warehouse_id,
        ws.unique_items_sold,
        ws.total_sales_profit,
        CASE 
            WHEN ws.total_sales_profit IS NULL OR ws.total_sales_profit = 0 THEN 'No Sales' 
            ELSE 'Sales Recorded' 
        END AS sales_status,
        SUM(ws.total_sales_profit) OVER (PARTITION BY ti.i_item_id) AS cumulative_profit,
        RANK() OVER (ORDER BY ws.total_sales_profit DESC) AS warehouse_rank
    FROM 
        TopItems ti
    JOIN 
        WarehouseSummary ws ON ws.unique_items_sold > 0 OR ti.total_quantity > 0
)
SELECT 
    f.*,
    CASE
        WHEN f.cumulative_profit IS NULL OR f.cumulative_profit < 1000 THEN 'Low Profit'
        WHEN f.cumulative_profit BETWEEN 1000 AND 5000 THEN 'Moderate Profit'
        ELSE 'High Profit'
    END AS profit_category
FROM 
    FinalAggregation f
WHERE 
    f.sales_status != 'No Sales'
ORDER BY 
    f.warehouse_rank, f.cumulative_profit DESC;
