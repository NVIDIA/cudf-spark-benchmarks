
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND 
                               (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
TopPerformers AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_profit,
        COALESCE(i.i_product_name, 'Unknown Product') AS product_name,
        w.w_warehouse_name,
        LEAD(rs.total_profit) OVER (ORDER BY rs.total_profit DESC) AS next_profit,
        NULLIF(rs.total_profit - LAG(rs.total_profit) OVER (ORDER BY rs.total_profit DESC), 0) AS profit_change
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        inventory inv ON inv.inv_item_sk = rs.ws_item_sk
    LEFT JOIN 
        warehouse w ON w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE 
        rs.rank = 1
)
SELECT 
    tp.product_name,
    tp.total_quantity,
    tp.total_profit,
    tp.w_warehouse_name,
    CASE 
        WHEN tp.profit_change IS NULL THEN 'No Change'
        WHEN tp.profit_change > 0 THEN 'Increased'
        WHEN tp.profit_change < 0 THEN 'Decreased'
        ELSE 'Stable'
    END AS profit_trend
FROM 
    TopPerformers tp
WHERE 
    tp.total_profit IS NOT NULL
ORDER BY 
    tp.total_profit DESC
LIMIT 10;
