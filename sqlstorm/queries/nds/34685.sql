
WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buying_potential,
        COALESCE(ib.ib_lower_bound, 0) AS income_lower,
        COALESCE(ib.ib_upper_bound, 999999) AS income_upper,
        hd.hd_dep_count AS dep_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
sales_growth AS (
    SELECT 
        cu.c_customer_sk AS customer_id,
        cu.full_name,
        cu.cd_gender,
        cu.cd_marital_status,
        cu.buying_potential,
        cu.income_lower,
        cu.income_upper,
        cu.dep_count,
        ss.total_quantity,
        ss.total_paid,
        CASE 
            WHEN ss.total_paid IS NULL THEN 'No Sales'
            WHEN ss.total_paid > 500 THEN 'High Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM customer_info cu
    LEFT JOIN sales_summary ss ON cu.c_customer_sk = ss.customer_id
)
SELECT 
    s.customer_value,
    COUNT(s.customer_id) AS customer_count,
    AVG(s.total_paid) AS avg_spent,
    MAX(s.total_quantity) AS max_quantity,
    MIN(s.total_quantity) AS min_quantity,
    COUNT(DISTINCT s.buying_potential) AS unique_buying_potentials,
    SUM(CASE WHEN s.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    SUM(CASE WHEN s.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers
FROM sales_growth s
GROUP BY 
    s.customer_value
ORDER BY 
    customer_count DESC
LIMIT 10;
