
WITH sales_summary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_net_profit) AS total_net_profit,
        AVG(cs_sales_price) AS avg_sales_price
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450000 AND 2450200
    GROUP BY cs_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COALESCE(NULLIF(cd.cd_marital_status, 'S'), 'Single') AS marital_status,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.total_net_profit) AS total_profit
    FROM customer_summary c
    JOIN sales_summary ss ON c.c_customer_sk = ss.cs_item_sk
    GROUP BY c.c_customer_sk
    ORDER BY total_profit DESC
    LIMIT 10
)
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    cs.total_returns, 
    cs.marital_status, 
    cs.cd_gender, 
    ib.ib_lower_bound, 
    ib.ib_upper_bound
FROM top_customers tc
JOIN customer c ON tc.c_customer_sk = c.c_customer_sk
JOIN customer_summary cs ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN income_band ib ON cs.hd_income_band_sk = ib.ib_income_band_sk
WHERE cs.total_returns > 0
ORDER BY cs.total_returns DESC, tc.total_profit DESC;
