
WITH  DailySales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        date_dim d
        LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
    UNION ALL
    SELECT 
        d.d_date,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        date_dim d
        LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    GROUP BY 
        d.d_date
),
SalesSummary AS (
    SELECT 
        d.d_date,
        COALESCE(SUM(ds.total_quantity), 0) AS total_quantity_sold,
        COALESCE(SUM(ds.total_profit), 0) AS total_profit_made
    FROM 
        DailySales ds 
    RIGHT JOIN date_dim d ON ds.d_date = d.d_date
    GROUP BY 
        d.d_date
),
TopStores AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_profit) AS store_profit
    FROM 
        store s
        LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_id
    HAVING 
        SUM(ss.ss_net_profit) IS NOT NULL
    ORDER BY 
        store_profit DESC
    LIMIT 5
)
SELECT 
    ss.d_date,
    ss.total_quantity_sold,
    ss.total_profit_made,
    ts.s_store_id,
    ts.store_profit
FROM 
    SalesSummary ss
LEFT JOIN TopStores ts ON ts.store_profit > 100000
WHERE 
    ss.total_profit_made > 5000
ORDER BY 
    ss.d_date DESC, 
    ts.store_profit DESC;
