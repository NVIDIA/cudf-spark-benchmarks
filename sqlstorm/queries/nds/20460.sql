
WITH demographic_analysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd_dep_count) AS avg_dep_count,
        MAX(cd_credit_rating) AS max_credit_rating,
        MIN(cd_credit_rating) AS min_credit_rating
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),

sales_performance AS (
    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS transaction_count,
        SUM(ss_quantity) AS total_quantity,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),

address_count AS (
    SELECT 
        c_current_addr_sk,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer
    GROUP BY 
        c_current_addr_sk
),

customer_addresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        COALESCE(NULLIF(ca_zip, ''), '00000') AS zip_code,
        (
            SELECT 
                COUNT(*)
            FROM 
                customer c
            WHERE 
                c.c_current_addr_sk = ca_address_sk
        ) AS customers_in_address
    FROM 
        customer_address
)

SELECT 
    da.cd_gender,
    da.cd_marital_status,
    da.cd_education_status,
    da.customer_count AS total_customers,
    da.total_purchase_estimate,
    da.avg_dep_count,
    sa.ss_store_sk,
    sa.total_sales,
    sa.transaction_count,
    sa.total_quantity,
    ca.ca_city,
    ca.ca_state,
    ca.zip_code,
    ca.customers_in_address
FROM 
    demographic_analysis da
JOIN 
    sales_performance sa ON da.customer_count > 10
LEFT JOIN 
    customer_addresses ca ON ca.customers_in_address > 5
WHERE 
    EXISTS (SELECT 1 
            FROM customer c 
            WHERE c.c_current_addr_sk IS NOT NULL AND c.c_current_addr_sk = ca.ca_address_sk)
ORDER BY 
    da.total_purchase_estimate DESC, 
    sa.total_sales DESC
LIMIT 100;
