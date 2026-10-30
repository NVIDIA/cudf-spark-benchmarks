
WITH  date_range AS (
    SELECT d_date
    FROM date_dim
    WHERE d_date BETWEEN '2022-01-01' AND '2022-12-31'
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_birth_month,
        d.d_year,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT CASE WHEN ws.ws_net_profit < 0 THEN ws.ws_order_number END) AS total_returns
    FROM customer AS c
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN date_dim AS d ON d.d_date_sk = ws.ws_sold_date_sk OR d.d_date_sk = cs.cs_sold_date_sk
    WHERE d.d_year = 2022 AND (c.c_birth_month IS NOT NULL OR c.c_birth_month IS NOT NULL)
    GROUP BY c.c_customer_sk, c.c_birth_month, d.d_year
),
income_analysis AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(CASE 
            WHEN hd.hd_income_band_sk IS NOT NULL THEN hd.hd_income_band_sk
            ELSE NULL 
        END) AS avg_income_band,
        SUM(COALESCE(cs.cs_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) - COALESCE(sr.sr_net_loss, 0)) AS net_spent
    FROM household_demographics AS hd
    LEFT JOIN customer_demographics AS cd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_sales AS cs ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales AS ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns AS sr ON sr.sr_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk
),
final_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        ia.avg_income_band,
        ia.net_spent,
        DENSE_RANK() OVER (PARTITION BY cs.c_birth_month ORDER BY cs.total_spent DESC) AS spending_rank
    FROM customer_summary AS cs
    JOIN income_analysis AS ia ON cs.c_customer_sk = ia.cd_demo_sk
    WHERE cs.total_orders > 0 OR ia.net_spent IS NOT NULL
)
SELECT 
    f.c_customer_sk,
    f.total_orders,
    f.total_spent,
    f.avg_income_band,
    f.net_spent,
    CASE 
        WHEN f.spending_rank <= 10 THEN 'High Spender'
        WHEN f.spending_rank <= 100 THEN 'Moderate Spender'
        ELSE 'Low Spender'
    END AS spender_category
FROM final_summary AS f
WHERE f.net_spent IS NOT NULL
AND f.total_spent > (SELECT AVG(total_spent) FROM final_summary)
ORDER BY f.total_spent DESC;
