
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
profit_bands AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(*) AS customer_count,
        AVG(sh.total_profit) AS avg_profit
    FROM 
        household_demographics hd
    LEFT JOIN 
        sales_hierarchy sh ON hd.hd_demo_sk = sh.c_customer_sk
    GROUP BY 
        hd.hd_income_band_sk
), 
seasonal_sales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS annual_profit,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    p.hd_income_band_sk,
    p.customer_count,
    p.avg_profit,
    s.d_year,
    s.annual_profit
FROM 
    profit_bands p
JOIN 
    seasonal_sales s ON p.customer_count > 100
WHERE 
    (p.avg_profit IS NOT NULL OR p.customer_count > 0)
ORDER BY 
    p.hd_income_band_sk, s.d_year DESC
LIMIT 5 OFFSET 10;
