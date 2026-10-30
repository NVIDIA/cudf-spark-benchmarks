
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        COALESCE(NULLIF(cd.cd_marital_status, ''), 'Unknown') AS marital_status,
        COALESCE(NULLIF(cd.cd_education_status, ''), 'None') AS education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
DemographicSales AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.marital_status,
        cd.education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.ca_city,
        cd.ca_state,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.order_count, 0) AS order_count
    FROM 
        CustomerData cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    marital_status,
    education_status,
    cd_purchase_estimate,
    cd_credit_rating,
    ca_city,
    ca_state,
    total_sales,
    total_quantity,
    order_count,
    CASE 
        WHEN total_sales > 5000 THEN 'High Value Customer'
        WHEN total_sales > 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer' 
    END AS customer_segment
FROM 
    DemographicSales
ORDER BY 
    total_sales DESC, full_name;
