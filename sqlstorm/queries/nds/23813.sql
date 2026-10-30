
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
ErrorProneSales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_net_profit < 0
    GROUP BY 
        cs.cs_item_sk, cs.cs_order_number
    HAVING 
        SUM(cs.cs_quantity) > 0
),
FullSalesData AS (
    SELECT 
        i.i_item_id,
        COALESCE(rs.total_quantity, 0) AS web_quantity,
        COALESCE(rs.total_profit, 0) AS web_profit,
        COALESCE(es.total_quantity, 0) AS catalog_quantity,
        COALESCE(es.total_profit, 0) AS catalog_profit
    FROM 
        item i
    LEFT JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    FULL OUTER JOIN 
        ErrorProneSales es ON i.i_item_sk = es.cs_item_sk
)
SELECT 
    fsd.i_item_id,
    fsd.web_quantity,
    fsd.web_profit,
    fsd.catalog_quantity,
    fsd.catalog_profit,
    CASE 
        WHEN fsd.web_profit > fsd.catalog_profit THEN 'Web Sales More Profitable'
        WHEN fsd.web_profit < fsd.catalog_profit THEN 'Catalog Sales More Profitable'
        ELSE 'Equal Profit'
    END AS profit_comparison,
    CASE 
        WHEN fsd.web_quantity IS NULL OR fsd.catalog_quantity IS NULL THEN 'Incomplete Data'
        ELSE 'Complete Data'
    END AS data_quality
FROM 
    FullSalesData fsd
WHERE 
    (fsd.web_quantity + fsd.catalog_quantity) > 0
    OR COALESCE(fsd.web_quantity, 0) = 0 AND COALESCE(fsd.catalog_quantity, 0) = 0
ORDER BY 
    fsd.web_profit DESC,
    fsd.catalog_profit DESC;
