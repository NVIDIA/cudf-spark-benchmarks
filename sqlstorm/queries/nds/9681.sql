
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        cs.cs_item_sk
),
TopProfitableItems AS (
    SELECT 
        i.i_item_id,
        rs.total_quantity,
        rs.total_profit
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.cs_item_sk = i.i_item_sk
    WHERE 
        rs.profit_rank <= 10
)
SELECT 
    tpi.i_item_id,
    tpi.total_quantity,
    tpi.total_profit,
    CASE 
        WHEN tpi.total_profit > 100000 THEN 'Very High'
        WHEN tpi.total_profit BETWEEN 50000 AND 100000 THEN 'High'
        WHEN tpi.total_profit BETWEEN 10000 AND 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profitability_level
FROM 
    TopProfitableItems tpi
ORDER BY 
    tpi.total_profit DESC;
