
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
        c.c_email_address,
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
SalesOverview AS (
    SELECT 
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ws.ws_bill_customer_sk
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerBenchmark AS (
    SELECT 
        cd.c_customer_sk,
        cd.full_name,
        cd.full_address,
        cd.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COALESCE(so.total_sales, 0) AS total_sales,
        COALESCE(so.total_orders, 0) AS total_orders
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesOverview so ON cd.c_customer_sk = so.ws_bill_customer_sk
)
SELECT 
    cb.full_name,
    cb.full_address,
    cb.c_email_address,
    cb.cd_gender,
    cb.cd_marital_status,
    cb.cd_education_status,
    cb.cd_purchase_estimate,
    cb.total_sales,
    cb.total_orders,
    CASE
        WHEN cb.total_sales > 1000 THEN 'High Value Customer'
        WHEN cb.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM 
    CustomerBenchmark cb
ORDER BY 
    cb.total_sales DESC, cb.full_name;
