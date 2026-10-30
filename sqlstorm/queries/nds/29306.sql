
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        sd.total_sales,
        sd.total_orders,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData sd ON ci.c_customer_sk = sd.c_customer_sk
    WHERE 
        sd.total_sales > 1000
)
SELECT 
    full_name,
    CONCAT(total_orders, ' orders, \$', ROUND(total_sales, 2)) AS sales_summary,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status
FROM 
    HighValueCustomers
ORDER BY 
    total_sales DESC;
