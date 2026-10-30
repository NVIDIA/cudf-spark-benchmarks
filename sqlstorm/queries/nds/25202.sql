
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
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        sd.total_sales,
        sd.order_count
    FROM 
        CustomerDetails cd
    JOIN 
        customer_address ca ON cd.c_customer_sk = ca.ca_address_sk
    JOIN 
        AddressDetails ad ON ca.ca_address_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesDetails sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    c_first_name,
    c_last_name,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS order_count,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales > 0 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    CustomerSales
WHERE 
    ca_state = 'CA'
ORDER BY 
    total_sales DESC, c_last_name ASC;
