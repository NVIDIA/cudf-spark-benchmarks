
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressData AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer_address ca
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ad.ca_city,
        ad.ca_state,
        ad.full_address,
        ss.total_orders,
        ss.total_sales
    FROM 
        CustomerData cd
    JOIN 
        AddressData ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesSummary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    *,
    CONCAT(c_first_name, ' ', c_last_name) AS full_name,
    CONCAT(ca_city, ', ', ca_state) AS location,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value' 
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value' 
        ELSE 'Low Value' 
    END AS customer_value
FROM 
    FinalReport
WHERE 
    cd_gender = 'F'
ORDER BY 
    total_sales DESC
LIMIT 100;
