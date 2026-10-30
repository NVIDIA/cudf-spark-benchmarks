
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS first_purchase_date,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_marital_status AS marital_status,
        cd_education_status AS education_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_credit_rating IN ('Low', 'Medium') THEN 'Low/Medium'
            ELSE 'High'
        END AS credit_rating,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS orders_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
combined_data AS (
    SELECT 
        cust.full_name,
        cust.gender,
        cust.marital_status,
        cust.education_status,
        cust.credit_rating,
        cust.ca_city,
        cust.ca_state,
        COALESCE(sales.total_sales, 0) AS total_sales,
        COALESCE(sales.orders_count, 0) AS orders_count,
        EXTRACT(YEAR FROM first_purchase_date) AS first_purchase_year
    FROM 
        customer_data cust
    LEFT JOIN 
        sales_data sales ON cust.c_customer_sk = sales.ws_bill_customer_sk
)
SELECT 
    gender,
    SUM(total_sales) AS total_sales_by_gender,
    COUNT(DISTINCT full_name) AS customer_count,
    AVG(first_purchase_year) AS avg_first_purchase_year
FROM 
    combined_data
GROUP BY 
    gender
ORDER BY 
    total_sales_by_gender DESC;
