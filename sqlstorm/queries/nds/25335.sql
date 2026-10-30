
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        REPLACE(c.c_email_address, '@example.com', '@company.com') AS modified_email,
        CONCAT('Customer-', c.c_customer_id) AS custom_id
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        cd.modified_email,
        cd.custom_id,
        COALESCE(sd.total_orders, 0) AS total_orders,
        COALESCE(sd.total_sales, 0.00) AS total_sales,
        COALESCE(sd.total_quantity, 0) AS total_quantity
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesDetails sd ON cd.c_customer_sk = sd.customer_id
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    FinalReport
ORDER BY 
    total_sales DESC;
