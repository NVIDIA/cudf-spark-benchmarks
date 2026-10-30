
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CASE 
            WHEN cd.cd_purchase_estimate < 500 THEN 'Low Value'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1500 THEN 'Medium Value'
            ELSE 'High Value'
        END AS customer_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer_address ca
),
SalesSummary AS (
    SELECT 
        cs.cs_bill_customer_sk,
        COUNT(cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_paid) AS total_revenue
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_bill_customer_sk
),
FinalResult AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.customer_value,
        ad.full_address,
        COALESCE(ss.total_orders, 0) AS total_orders,
        COALESCE(ss.total_revenue, 0) AS total_revenue
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesSummary ss ON cd.c_customer_sk = ss.cs_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    customer_value,
    full_address,
    total_orders,
    total_revenue,
    total_revenue / NULLIF(total_orders, 0) AS avg_order_value
FROM 
    FinalResult
ORDER BY 
    total_revenue DESC
LIMIT 100;
