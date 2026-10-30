
WITH  sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
customer_details AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        s.s_store_name,
        COALESCE(d.d_year, 2023) AS year
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN store s ON c.c_customer_sk = s.s_store_sk
    LEFT JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
top_customers AS (
    SELECT
        cs.ws_bill_customer_sk AS customer_sk,
        SUM(cs.ws_net_paid) AS total_net_paid
    FROM web_sales cs
    GROUP BY cs.ws_bill_customer_sk
    HAVING SUM(cs.ws_net_paid) > 1000
)
SELECT
    cd.c_first_name,
    cd.c_last_name,
    cd.ca_city,
    cd.cd_gender,
    ss.total_sales,
    ss.order_count,
    CASE 
        WHEN ss.order_count > 5 THEN 'High Activity'
        WHEN ss.order_count BETWEEN 3 AND 5 THEN 'Medium Activity'
        ELSE 'Low Activity'
    END AS activity_level,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM customer_details cd
JOIN sales_summary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN household_demographics hd ON cd.c_customer_sk = hd.hd_demo_sk
LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ss.total_sales IS NOT NULL
AND cd.cd_gender = 'F' 
AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
ORDER BY ss.total_sales DESC
LIMIT 100;
