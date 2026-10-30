
WITH  SalesGrowth AS (
    SELECT 
        d_year,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY d_year ORDER BY SUM(ws_net_profit) DESC) AS rank_year
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year BETWEEN 2015 AND 2022
    GROUP BY 
        d_year
), 
TopProfitableYears AS (
    SELECT 
        d_year,
        total_profit
    FROM 
        SalesGrowth
    WHERE 
        rank_year <= 3
)
SELECT 
    t.d_year,
    t.total_profit,
    COALESCE((SELECT MAX(total_profit) FROM TopProfitableYears WHERE d_year < t.d_year), 0) AS previous_year_profit,
    (t.total_profit - COALESCE((SELECT MAX(total_profit) FROM TopProfitableYears WHERE d_year < t.d_year), 0)) AS growth_difference
FROM 
    TopProfitableYears t
FULL OUTER JOIN 
    (SELECT DISTINCT d_year FROM date_dim WHERE d_year BETWEEN 2015 AND 2022) d ON t.d_year = d.d_year
ORDER BY 
    t.d_year;
