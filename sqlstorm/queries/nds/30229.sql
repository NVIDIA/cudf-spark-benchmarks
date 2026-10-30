
WITH  SalesGrowth AS (
    SELECT 
        d_year,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (ORDER BY d_year) AS year_rank
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
    HAVING 
        SUM(ws_net_profit) > 10000
    UNION ALL
    SELECT 
        d.d_year,
        SUM(cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (ORDER BY d.d_year) AS year_rank
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year > (SELECT MIN(d_year) FROM date_dim)
    GROUP BY 
        d.d_year
    HAVING 
        SUM(cs_net_profit) > 15000
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY AVG(cd_purchase_estimate) DESC) AS gender_rank
    FROM 
        customer_demographics cd 
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    sg.d_year,
    sg.total_profit,
    cs.cd_gender,
    cs.customer_count,
    cs.avg_purchase_estimate
FROM 
    SalesGrowth sg
FULL OUTER JOIN 
    CustomerStats cs ON sg.year_rank = cs.gender_rank
WHERE 
    (sg.total_profit IS NOT NULL AND cs.customer_count IS NOT NULL)
    OR (sg.total_profit IS NULL AND cs.avg_purchase_estimate > 100)
ORDER BY 
    sg.d_year DESC, cs.customer_count DESC;
