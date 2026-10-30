
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_dep_count,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        CD.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        LOWER(cd.cd_gender) = 'f' AND
        cd.cd_marital_status = 'M'
),
sales_summary AS (
    SELECT
        cs_bill_customer_sk AS customer_sk,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_quantity) AS total_quantity
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip,
    ci.name_length,
    ss.total_orders,
    ss.total_sales,
    ss.total_quantity,
    ci.cd_credit_rating
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.customer_sk
ORDER BY 
    ss.total_sales DESC, 
    ci.name_length ASC
LIMIT 100;
