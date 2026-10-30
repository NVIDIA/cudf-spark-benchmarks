
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_education_status AS education,
        cd.cd_purchase_estimate AS purchase_estimate,
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
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        cd.full_name,
        cd.gender,
        cd.marital_status,
        cd.education,
        cd.purchase_estimate,
        cd.ca_city,
        cd.ca_state,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesSummary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    full_name,
    gender,
    marital_status,
    education,
    purchase_estimate,
    ca_city,
    ca_state,
    total_sales,
    order_count,
    CASE 
        WHEN order_count > 0 THEN ROUND(total_sales / order_count, 2)
        ELSE 0
    END AS average_order_value
FROM 
    CustomerSales
WHERE 
    purchase_estimate > 1000
ORDER BY 
    total_sales DESC
LIMIT 100;
