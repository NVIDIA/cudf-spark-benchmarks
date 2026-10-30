
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0 AND ws_quantity IS NOT NULL
),
ReturnStats AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        COUNT(wr_order_number) AS return_count,
        COALESCE(SUM(wr_return_quantity), 0) AS valid_return_quantity
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
FinalSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.ws_sales_price,
        COALESCE(rs.ws_net_profit, 0) - COALESCE(r.total_returned, 0) AS net_profit_after_returns
    FROM 
        RankedSales rs
    LEFT JOIN 
        ReturnStats r ON rs.ws_item_sk = r.wr_item_sk
    WHERE 
        rs.rn = 1
)
SELECT 
    fs.ws_order_number,
    fs.ws_item_sk,
    fs.ws_quantity,
    fs.ws_sales_price,
    fs.net_profit_after_returns,
    CASE 
        WHEN fs.net_profit_after_returns > 0 THEN 'Profitable'
        WHEN fs.net_profit_after_returns < 0 THEN 'Loss'
        ELSE 'Break-even' 
    END AS profitability_status,
    CONCAT('Item ID: ', CAST(fs.ws_item_sk AS VARCHAR(255)), ' | Quantity Sold: ', CAST(fs.ws_quantity AS VARCHAR(255))) AS item_summary,
    CASE 
        WHEN fs.ws_quantity = 0 OR fs.ws_sales_price IS NULL THEN NULL
        ELSE ROUND((fs.net_profit_after_returns / fs.ws_quantity), 2) 
    END AS avg_profit_per_item
FROM 
    FinalSales fs
WHERE 
    fs.net_profit_after_returns IS NOT NULL
ORDER BY 
    fs.net_profit_after_returns DESC
LIMIT 100;
