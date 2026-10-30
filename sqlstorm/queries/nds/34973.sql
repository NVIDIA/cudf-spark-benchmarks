
WITH  sales_hierarchy AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid_inc_tax) DESC) AS rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low' 
        END AS purchase_category
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        sh.ss_store_sk, 
        SUM(sh.ss_net_paid_inc_tax) AS total_income,
        COUNT(DISTINCT sh.ss_ticket_number) AS total_transactions,
        AVG(COALESCE(ss_ext_discount_amt, 0)) AS avg_discount
    FROM 
        store_sales sh
    GROUP BY 
        sh.ss_store_sk
)
SELECT 
    si.ss_store_sk,
    COALESCE(si.total_income, 0) AS total_income,
    COALESCE(si.total_transactions, 0) AS total_transactions,
    si.avg_discount,
    COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
    MAX(si.total_income) OVER () AS max_store_income,
    MIN(si.avg_discount) OVER () AS min_avg_discount,
    rh.total_sales AS hierarchy_rank_sales
FROM 
    sales_summary si
LEFT JOIN 
    sales_hierarchy rh ON si.ss_store_sk = rh.ss_store_sk
LEFT JOIN 
    customer_info ci ON si.ss_store_sk = ci.hd_income_band_sk
WHERE 
    (si.total_income > 5000 OR si.total_transactions > 100)
    AND ci.cd_gender = 'F'
GROUP BY 
    si.ss_store_sk,
    si.total_income,
    si.total_transactions,
    si.avg_discount,
    rh.total_sales
ORDER BY 
    total_income DESC
LIMIT 10;
