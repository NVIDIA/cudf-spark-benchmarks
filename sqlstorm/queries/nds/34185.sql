
WITH  sales_cte AS (
    SELECT 
        ss_customer_sk, 
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
),
demographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        cd_purchase_estimate, 
        cd_credit_rating
    FROM 
        customer_demographics
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    si.total_sales,
    si.transaction_count,
    CASE 
        WHEN si.total_sales > 1000 THEN 'High Spender'
        WHEN si.total_sales BETWEEN 500 AND 1000 THEN 'Moderate Spender'
        ELSE 'Low Spender'
    END AS spending_category,
    DENSE_RANK() OVER (PARTITION BY ci.ca_state ORDER BY si.total_sales DESC) AS sales_rank
FROM 
    customer_info ci
JOIN 
    sales_cte si ON ci.c_customer_sk = si.ss_customer_sk
WHERE 
    ci.ca_state IS NOT NULL
    AND (ci.cd_marital_status IS NULL OR ci.cd_marital_status = 'S')
    AND ci.c_first_name LIKE 'A%'
ORDER BY 
    ci.ca_state, sales_rank
LIMIT 50;
