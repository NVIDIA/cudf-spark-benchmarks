
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS total_customers,
        AVG(CASE WHEN cd_gender = 'M' THEN ws.ws_net_paid ELSE NULL END) AS avg_male_spending,
        AVG(CASE WHEN cd_gender = 'F' THEN ws.ws_net_paid ELSE NULL END) AS avg_female_spending
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
monthly_trends AS (
    SELECT 
        sales_year, 
        sales_month, 
        total_net_profit,
        total_orders,
        total_customers,
        avg_male_spending,
        avg_female_spending,
        LAG(total_net_profit) OVER (ORDER BY sales_year, sales_month) AS prev_month_net_profit,
        (total_net_profit - LAG(total_net_profit) OVER (ORDER BY sales_year, sales_month)) / NULLIF(LAG(total_net_profit) OVER (ORDER BY sales_year, sales_month), 0) * 100 AS growth_rate
    FROM 
        sales_summary
)
SELECT 
    sales_year,
    sales_month,
    total_net_profit,
    total_orders,
    total_customers,
    avg_male_spending,
    avg_female_spending,
    prev_month_net_profit,
    growth_rate
FROM 
    monthly_trends
WHERE 
    sales_year = 2023
ORDER BY 
    sales_month;
