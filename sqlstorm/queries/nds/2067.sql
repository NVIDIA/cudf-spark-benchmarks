
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        i.i_brand,
        i.i_category
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2452000 AND 2452060
),
ProfitRank AS (
    SELECT
        sd.*,
        RANK() OVER (PARTITION BY sd.i_category ORDER BY sd.ws_net_profit DESC) AS profit_rank
    FROM 
        SalesData sd
),
TopProfit AS (
    SELECT 
        p.i_category,
        p.i_brand,
        SUM(p.ws_net_profit) AS total_net_profit
    FROM 
        ProfitRank p
    WHERE 
        p.profit_rank <= 5
    GROUP BY 
        p.i_category, p.i_brand
),
OverallStats AS (
    SELECT 
        i_category,
        COUNT(DISTINCT i_brand) AS brand_count,
        SUM(total_net_profit) AS category_net_profit
    FROM 
        TopProfit
    GROUP BY 
        i_category
)
SELECT 
    os.i_category,
    os.brand_count,
    os.category_net_profit,
    CASE
        WHEN os.category_net_profit > 5000 THEN 'High Profit'
        WHEN os.category_net_profit BETWEEN 1000 AND 5000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    OverallStats os
ORDER BY 
    os.category_net_profit DESC;
