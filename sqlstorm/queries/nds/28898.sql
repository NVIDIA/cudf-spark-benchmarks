
WITH customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LEFT(c.c_email_address, POSITION('@' IN c.c_email_address) - 1) AS email_prefix
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk
),
gender_summary AS (
    SELECT
        cd_gender,
        COUNT(*) AS customer_count
    FROM customer_details
    GROUP BY cd_gender
)
SELECT 
    cd.full_name,
    cd.email_prefix,
    COALESCE(gs.total_sales, 0) AS total_sales,
    COALESCE(gs.order_count, 0) AS order_count,
    gd.customer_count AS gender_count
FROM customer_details cd
LEFT JOIN sales_summary gs ON cd.c_customer_sk = gs.cs_bill_customer_sk
JOIN gender_summary gd ON cd.cd_gender = gd.cd_gender
WHERE cd.ca_state = 'CA'
ORDER BY total_sales DESC
LIMIT 10;
