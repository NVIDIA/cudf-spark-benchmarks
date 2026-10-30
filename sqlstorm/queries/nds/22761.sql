
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS ProfitRank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
FilteredReturns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns
    FROM 
        web_returns
    WHERE 
        wr_return_quantity > 0
    GROUP BY 
        wr_item_sk
),
AggregateData AS (
    SELECT 
        i.i_item_id,
        COALESCE(MAX(rs.ws_sales_price), 0) AS max_sale_price,
        COALESCE(SUM(fr.total_returns), 0) AS total_returns,
        AVG(CASE WHEN rs.ProfitRank = 1 THEN rs.ws_net_profit END) AS avg_top_profit,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        item i
    LEFT JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN 
        FilteredReturns fr ON i.i_item_sk = fr.wr_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    a.i_item_id,
    a.max_sale_price,
    a.total_returns,
    a.avg_top_profit,
    a.total_net_profit,
    CASE 
        WHEN a.max_sale_price > 1000 THEN 'High Value'
        WHEN a.max_sale_price BETWEEN 500 AND 999 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS price_category
FROM 
    AggregateData a
LEFT JOIN 
    store s ON s.s_store_sk IN (
        SELECT DISTINCT ss.ss_store_sk 
        FROM store_sales ss
        WHERE ss.ss_item_sk IN (SELECT i.i_item_sk FROM item i)
    )
WHERE 
    a.total_returns >= (SELECT AVG(total_returns) FROM FilteredReturns)
ORDER BY 
    a.total_net_profit DESC;
