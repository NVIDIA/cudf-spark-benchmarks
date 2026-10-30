
WITH  sales_cte AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_net_profit) as total_profit,
        RANK() OVER (ORDER BY SUM(ss_net_profit) DESC) as store_rank
    FROM store_sales
    WHERE ss_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 
        AND d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim WHERE d_year = 2023)
    )
    GROUP BY ss_store_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        ci.cd_purchase_estimate,
        ci.hd_income_band_sk
    FROM customer_info ci
    WHERE ci.gender_rank <= 10
),
store_info AS (
    SELECT 
        s.s_store_sk, 
        s.s_store_name, 
        w.w_warehouse_name, 
        COALESCE(sa.total_profit, 0) as total_profit
    FROM store s
    LEFT JOIN warehouse w ON s.s_store_sk = w.w_warehouse_sk
    LEFT JOIN sales_cte sa ON s.s_store_sk = sa.ss_store_sk
)
SELECT 
    si.s_store_name,
    COUNT(tc.c_customer_sk) as num_top_customers,
    AVG(tc.cd_purchase_estimate) as avg_purchase_estimate,
    SUM(si.total_profit) as total_store_profit,
    CASE 
        WHEN MAX(si.total_profit) IS NULL THEN 'No Profit'
        ELSE 'Profitable'
    END as store_profit_status
FROM store_info si
LEFT JOIN top_customers tc ON si.s_store_sk = tc.c_customer_sk
GROUP BY si.s_store_name
HAVING SUM(si.total_profit) >= (
    SELECT AVG(total_profit)
    FROM sales_cte
) 
ORDER BY total_store_profit DESC;
