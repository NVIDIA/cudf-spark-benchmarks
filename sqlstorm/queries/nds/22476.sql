
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
        AND ws.ws_net_profit IS NOT NULL
),
FilteredSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.ws_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rn = 1
),
SalesStats AS (
    SELECT 
        fs.ws_item_sk,
        SUM(fs.ws_sales_price) AS total_sales,
        COUNT(fs.ws_order_number) AS order_count,
        AVG(fs.ws_net_profit) AS avg_net_profit
    FROM 
        FilteredSales fs
    GROUP BY 
        fs.ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_size,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count,
        COALESCE(ss.avg_net_profit, 0) AS avg_net_profit,
        CASE 
            WHEN i.i_current_price > 100 THEN 'High Price'
            WHEN i.i_current_price BETWEEN 50 AND 100 THEN 'Moderate Price'
            ELSE 'Low Price'
        END AS price_category
    FROM 
        item i
    LEFT JOIN 
        SalesStats ss ON i.i_item_sk = ss.ws_item_sk
),
ReturnItems AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
FinalAnalysis AS (
    SELECT 
        id.i_item_sk,
        id.i_item_desc,
        id.total_sales,
        id.order_count,
        id.avg_net_profit,
        ri.total_returns,
        id.price_category,
        CASE 
            WHEN id.order_count > 0 THEN (id.total_sales - COALESCE(ri.total_returns, 0) * id.i_current_price) / id.order_count
            ELSE NULL
        END AS adjusted_avg_price
    FROM 
        ItemDetails id
    LEFT JOIN 
        ReturnItems ri ON id.i_item_sk = ri.cr_item_sk
)
SELECT 
    fa.i_item_sk,
    fa.i_item_desc,
    fa.total_sales,
    fa.order_count,
    fa.avg_net_profit,
    fa.total_returns,
    fa.price_category,
    COALESCE(fa.adjusted_avg_price, 0) AS adjusted_avg_price,
    CASE 
        WHEN fa.avg_net_profit > 0 THEN 'Profitable'
        WHEN fa.total_returns > 0 THEN 'At Risk'
        ELSE 'Needs Attention'
    END AS profitability_status
FROM 
    FinalAnalysis fa
WHERE 
    fa.adjusted_avg_price IS NOT NULL
    AND NOT (fa.price_category = 'Low Price' AND fa.total_sales < 1000)
ORDER BY 
    fa.total_sales DESC
LIMIT 100;
