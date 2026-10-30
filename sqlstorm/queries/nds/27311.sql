
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerBenchmark AS (
    SELECT 
        cd.c_customer_sk,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        COALESCE(s.total_sales, 0) AS total_sales,
        s.order_count
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN 
        Sales s ON cd.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 10000 THEN 'High Value Customer'
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    CustomerBenchmark
WHERE 
    cd_gender = 'F' AND cd_marital_status = 'M'
ORDER BY 
    total_sales DESC;
