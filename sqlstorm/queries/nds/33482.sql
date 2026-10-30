
WITH  sales_growth AS (
    SELECT 
        d_year,
        SUM(CASE WHEN ws_sold_date_sk IS NOT NULL THEN ws_net_profit ELSE 0 END) AS total_net_profit
    FROM 
        date_dim
    LEFT JOIN 
        web_sales ON d_date_sk = ws_sold_date_sk
    GROUP BY 
        d_year
    ORDER BY 
        d_year
),
growth_calculation AS (
    SELECT 
        year_current.d_year,
        year_current.total_net_profit AS current_profit,
        LAG(year_current.total_net_profit) OVER (ORDER BY year_current.d_year) AS previous_profit,
        (year_current.total_net_profit - LAG(year_current.total_net_profit) OVER (ORDER BY year_current.d_year)) / NULLIF(LAG(year_current.total_net_profit) OVER (ORDER BY year_current.d_year), 0) * 100 AS growth_percentage
    FROM 
        sales_growth year_current
),
average_growth AS (
    SELECT 
        AVG(growth_percentage) AS avg_growth
    FROM 
        growth_calculation
    WHERE 
        growth_percentage IS NOT NULL
),
customer_segment AS (
    SELECT 
        cd_gender, 
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_credit_rating) AS max_credit_rating
    FROM 
        customer
    LEFT JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    cs.cd_gender,
    cs.customer_count,
    cs.avg_purchase_estimate,
    cs.max_credit_rating,
    g.growth_percentage,
    a.avg_growth
FROM 
    customer_segment cs
CROSS JOIN 
    growth_calculation g
CROSS JOIN 
    average_growth a
WHERE 
    cs.customer_count > (SELECT AVG(customer_count) FROM customer_segment)
ORDER BY 
    cs.customer_count DESC;
