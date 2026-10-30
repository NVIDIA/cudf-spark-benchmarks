
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    COALESCE(sd.total_sales, 0) AS total_sales_amount,
    COALESCE(sd.total_orders, 0) AS total_orders
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.customer_sk
WHERE 
    UPPER(cd.cd_gender) = 'F'
    AND cd.cd_purchase_estimate > 5000
ORDER BY 
    total_sales_amount DESC
LIMIT 
    100;
