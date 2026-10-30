
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS ProfitRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2023 AND d.d_moy IN (6, 7)
        )
),
SalesSummary AS (
    SELECT 
        COUNT(*) AS TotalSales,
        SUM(ws.ws_net_profit) AS TotalNetProfit,
        AVG(ws.ws_net_profit) AS AvgNetProfit,
        MAX(ws.ws_net_profit) AS MaxNetProfit,
        MIN(ws.ws_net_profit) AS MinNetProfit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
),
TopSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_quantity) AS TotalQuantity
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2023
        )
    GROUP BY 
        i.i_item_id, i.i_product_name
    ORDER BY 
        TotalQuantity DESC
    LIMIT 10
)
SELECT 
    COALESCE(ss.TotalSales, 0) AS TotalSales,
    COALESCE(ss.TotalNetProfit, 0) AS TotalNetProfit,
    COALESCE(ss.AvgNetProfit, 0) AS AvgNetProfit,
    COALESCE(ss.MaxNetProfit, 0) AS MaxNetProfit,
    COALESCE(ss.MinNetProfit, 0) AS MinNetProfit,
    t.i_item_id,
    t.i_product_name,
    t.TotalQuantity
FROM 
    SalesSummary ss
FULL OUTER JOIN TopSellingItems t ON ss.TotalSales IS NOT NULL OR t.TotalQuantity IS NOT NULL
ORDER BY 
    t.TotalQuantity DESC NULLS LAST;
