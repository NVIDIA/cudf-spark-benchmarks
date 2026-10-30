
WITH RankedSales AS (
    SELECT 
        s.s_store_name,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS ranking
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_ship_addr_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        s.s_store_name, ws.ws_sold_date_sk
)

SELECT 
    r.s_store_name,
    d.d_date AS sale_date,
    r.total_quantity,
    r.total_profit
FROM 
    RankedSales r
JOIN 
    date_dim d ON r.ws_sold_date_sk = d.d_date_sk
WHERE 
    r.ranking <= 5
ORDER BY 
    d.d_date, r.total_profit DESC;
