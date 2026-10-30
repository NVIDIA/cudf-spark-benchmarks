
WITH  SalesGrowth AS (
    SELECT 
        d_year, 
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
    UNION ALL
    SELECT 
        d_year, 
        SUM(ws_net_profit) 
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year < (SELECT MAX(d_year) FROM date_dim)
    GROUP BY 
        d_year
), GrowthTrends AS (
    SELECT 
        d_year, 
        total_profit,
        LAG(total_profit) OVER (ORDER BY d_year) AS previous_year_profit,
        CASE 
            WHEN LAG(total_profit) OVER (ORDER BY d_year) IS NULL THEN NULL
            ELSE (total_profit - LAG(total_profit) OVER (ORDER BY d_year)) / LAG(total_profit) OVER (ORDER BY d_year) * 100
        END AS growth_percentage
    FROM 
        SalesGrowth
),
CustomerCategories AS (
    SELECT 
        c.c_customer_sk, 
        cd_demo_sk, 
        cd_gender,
        CASE 
            WHEN hd_income_band_sk IS NOT NULL THEN 'Affluent'
            WHEN cd_purchase_estimate > 500 THEN 'High Value'
            ELSE 'Standard'
        END AS customer_category
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
)
SELECT 
    g.d_year,
    g.total_profit,
    g.growth_percentage,
    COUNT(DISTINCT cc.c_customer_sk) AS total_customers,
    SUM(CASE WHEN cc.customer_category = 'Affluent' THEN 1 ELSE 0 END) AS affluent_customers,
    SUM(CASE WHEN cc.customer_category = 'High Value' THEN 1 ELSE 0 END) AS high_value_customers
FROM 
    GrowthTrends g
LEFT JOIN 
    CustomerCategories cc ON g.d_year = EXTRACT(YEAR FROM TIMESTAMP '2002-10-01 12:34:56') 
GROUP BY 
    g.d_year, 
    g.total_profit, 
    g.growth_percentage
ORDER BY 
    g.d_year DESC;
