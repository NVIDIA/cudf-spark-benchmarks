
WITH sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count,
        AVG(ss_net_paid_inc_tax) AS avg_transaction_value,
        DENSE_RANK() OVER (ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY ss_store_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rnk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
),
top_stores AS (
    SELECT 
        ss.ss_store_sk,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_units_sold
    FROM store_sales ss
    INNER JOIN sales_summary ss_sum ON ss.ss_store_sk = ss_sum.ss_store_sk
    WHERE ss_sum.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
    GROUP BY ss.ss_store_sk
)

SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    ss.total_sales,
    ss.transaction_count,
    ss.avg_transaction_value,
    ts.total_units_sold,
    CASE 
        WHEN cs.rnk <= 5 THEN 'Top Customer' 
        ELSE 'Regular Customer' 
    END AS customer_type,
    CASE 
        WHEN ts.total_units_sold IS NULL THEN 'No Sales'
        WHEN ts.total_units_sold < 20 THEN 'Low Sales'
        WHEN ts.total_units_sold >= 20 AND ts.total_units_sold < 100 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM customer_info cs
JOIN sales_summary ss ON cs.c_customer_sk = ss.ss_store_sk
LEFT JOIN top_stores ts ON ss.ss_store_sk = ts.ss_store_sk
WHERE cs.cd_gender IS NOT NULL
AND (cs.cd_marital_status = 'M' OR cs.cd_marital_status IS NULL)
ORDER BY ss.total_sales DESC, cs.c_last_name, cs.c_first_name;
