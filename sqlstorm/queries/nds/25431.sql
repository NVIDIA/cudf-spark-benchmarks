
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        ci.c_customer_sk,
        ci.full_name,
        ci.c_email_address,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.ca_city,
        ci.ca_state,
        ss.total_sales,
        ss.order_count
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesSummary ss ON ci.c_customer_sk = ss.customer_sk
)
SELECT 
    full_name,
    c_email_address,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    ca_city,
    ca_state,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS order_count,
    (CASE 
        WHEN total_sales IS NULL THEN 'No Sales'
        WHEN total_sales >= 10000 THEN 'High Value Customer'
        WHEN total_sales >= 5000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END) AS customer_value
FROM 
    CustomerSales
ORDER BY 
    total_sales DESC
LIMIT 50;
