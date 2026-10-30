
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rnk
    FROM store_returns
    GROUP BY sr_item_sk
),
CombinedSales AS (
    SELECT 
        cs_item_sk AS item_sk,
        SUM(cs_net_profit) AS total_profit,
        SUM(cs_quantity) AS total_quantity,
        COALESCE(MAX(cr_return_quantity), 0) AS total_returns
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr ON cs.cs_item_sk = cr.cr_item_sk
    GROUP BY cs_item_sk
), 
SalesSummary AS (
    SELECT 
        ws_item_sk AS item_sk,
        SUM(ws_net_profit) AS total_web_profit,
        SUM(ws_quantity) AS total_web_quantity
    FROM web_sales
    GROUP BY ws_item_sk
),
FinalReport AS (
    SELECT
        c_item.item_sk,
        COALESCE(c_item.total_profit, 0) AS catalog_profit,
        COALESCE(c_item.total_quantity, 0) AS catalog_quantity,
        COALESCE(w_item.total_web_profit, 0) AS web_profit,
        COALESCE(w_item.total_web_quantity, 0) AS web_quantity,
        COALESCE(r_item.total_returns, 0) AS returns_count,
        CASE 
            WHEN COALESCE(c_item.total_quantity, 0) = 0 THEN 'No Sales'
            WHEN COALESCE(r_item.total_returns, 0) > COALESCE(c_item.total_quantity, 0) THEN 'High Return Rate'
            ELSE 'Normal' 
        END AS status
    FROM CombinedSales AS c_item
    FULL OUTER JOIN SalesSummary AS w_item ON c_item.item_sk = w_item.item_sk
    FULL OUTER JOIN RankedReturns AS r_item ON c_item.item_sk = r_item.sr_item_sk
    WHERE (c_item.total_profit IS NOT NULL OR w_item.total_web_profit IS NOT NULL)
      AND (r_item.rnk = 1 OR r_item.rnk IS NULL)
)
SELECT 
   COUNT(*) AS report_count,
   SUM(CASE WHEN status = 'High Return Rate' THEN 1 ELSE 0 END) AS high_return_report
FROM FinalReport
WHERE catalog_profit > 10000
  AND (web_profit IS NULL OR web_profit < 5000)
  AND (web_quantity IS NOT NULL AND web_quantity > catalog_quantity)
  AND status IS NOT NULL
GROUP BY status
HAVING AVG(catalog_quantity) > 5
ORDER BY report_count DESC;
