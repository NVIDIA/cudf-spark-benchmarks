
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        RANK() OVER (ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
)
SELECT 
    s_store_id,
    rs.total_net_profit
FROM 
    store s
JOIN 
    RankedSales rs ON s.s_store_sk = rs.ss_store_sk
WHERE 
    rs.profit_rank <= 10
ORDER BY 
    rs.total_net_profit DESC;
