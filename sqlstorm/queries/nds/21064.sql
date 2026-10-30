
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        ws_net_profit, 
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_net_paid_inc_ship > 50.00 
        AND ((ws_sales_price > 20 AND ws_sales_price < 100) OR ws_net_profit IS NULL)
),
SalesSummary AS (
    SELECT 
        rs.ws_item_sk,
        COUNT(*) AS total_sales,
        SUM(rs.ws_sales_price) AS total_revenue,
        AVG(rs.ws_net_profit) AS avg_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.profit_rank = 1
    GROUP BY 
        rs.ws_item_sk
),
SalesExpected AS (
    SELECT 
        cs_item_sk,
        SUM(cs_ext_sales_price) AS expected_revenue
    FROM 
        catalog_sales
    WHERE 
        cs_item_sk IN (SELECT DISTINCT ws_item_sk FROM RankedSales)
    GROUP BY 
        cs_item_sk
)
SELECT 
    coalesce(ss.ws_item_sk, se.cs_item_sk) AS item_sk, 
    ss.total_sales, 
    ss.total_revenue, 
    ss.avg_profit,
    se.expected_revenue
FROM 
    SalesSummary ss
FULL OUTER JOIN 
    SalesExpected se ON ss.ws_item_sk = se.cs_item_sk
WHERE 
    (ss.total_sales > 10 OR ss.total_sales IS NULL)
    AND (se.expected_revenue IS NOT NULL OR ss.total_revenue < 1000)
ORDER BY 
    COALESCE(ss.avg_profit, 0) DESC, 
    COALESCE(se.expected_revenue, 0) ASC
LIMIT 100;
