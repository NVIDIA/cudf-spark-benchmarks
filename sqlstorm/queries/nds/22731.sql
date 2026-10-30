
WITH  customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS orders_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer AS c
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name
),
income_brackets AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NOT NULL AND ib.ib_upper_bound IS NOT NULL 
            THEN CONCAT('$', CAST(ib.ib_lower_bound AS STRING), ' - $', CAST(ib.ib_upper_bound AS STRING))
            ELSE 'Unknown Income Bracket'
        END AS income_range
    FROM household_demographics AS hd
    JOIN income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
customer_income AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_first_name,
        ib.income_range
    FROM customer_purchases AS cp
    JOIN customer_demographics AS cd ON cp.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN income_brackets AS ib ON cd.cd_demo_sk = ib.hd_demo_sk
),
promotional_metrics AS (
    SELECT 
        ps.p_promo_name,
        AVG(ps.p_cost) AS avg_cost,
        COUNT(ps.p_promo_sk) AS promo_count
    FROM promotion AS ps
    WHERE ps.p_start_date_sk < (SELECT MAX(d.d_date_sk) FROM date_dim AS d)
    GROUP BY ps.p_promo_name
),
final_report AS (
    SELECT 
        ci.c_first_name,
        ci.income_range,
        cp.total_sales,
        pm.promo_count,
        pm.avg_cost,
        COALESCE(cp.orders_count, 0) AS orders_count
    FROM customer_income AS ci
    LEFT JOIN customer_purchases AS cp ON ci.c_customer_sk = cp.c_customer_sk
    LEFT JOIN promotional_metrics AS pm ON cp.total_sales > pm.avg_cost
)
SELECT 
    fr.c_first_name,
    fr.income_range,
    fr.total_sales,
    fr.orders_count,
    CASE 
        WHEN fr.orders_count > 5 THEN 'Frequent Buyer'
        WHEN fr.total_sales IS NULL OR fr.total_sales < 100 THEN 'Low Engagement'
        ELSE 'Occasional Buyer'
    END AS customer_segment
FROM final_report AS fr
WHERE fr.total_sales IS NOT NULL
ORDER BY fr.total_sales DESC
LIMIT 10;
