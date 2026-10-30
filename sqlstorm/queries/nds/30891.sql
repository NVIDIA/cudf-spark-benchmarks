
WITH  SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales 
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
AggregatedSales AS (
    SELECT 
        sd.ws_sold_date_sk,
        i.i_item_id,
        i.i_item_desc,
        COALESCE(SUM(sd.total_quantity), 0) AS total_sold,
        COALESCE(SUM(sd.total_profit), 0) AS total_profit
    FROM 
        SalesData sd
    LEFT JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.rn = 1
    GROUP BY 
        sd.ws_sold_date_sk, i.i_item_id, i.i_item_desc
),
HighestProfits AS (
    SELECT 
        a.ws_sold_date_sk,
        a.i_item_id,
        a.i_item_desc,
        a.total_sold,
        a.total_profit,
        RANK() OVER (PARTITION BY a.ws_sold_date_sk ORDER BY a.total_profit DESC) AS profit_rank
    FROM 
        AggregatedSales a
)
SELECT 
    d.d_date AS sale_date,
    COUNT(DISTINCT h.i_item_id) AS top_items_count,
    AVG(h.total_profit) AS avg_profit
FROM 
    date_dim d
LEFT JOIN 
    HighestProfits h ON d.d_date_sk = h.ws_sold_date_sk AND h.profit_rank <= 5
WHERE 
    d.d_year = 2023
GROUP BY 
    d.d_date
ORDER BY 
    d.d_date;
