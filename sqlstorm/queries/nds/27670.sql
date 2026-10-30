
WITH CombinedCustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
JoinedSalesData AS (
    SELECT 
        ccd.c_customer_sk,
        ccd.full_name,
        ccd.cd_gender,
        ccd.cd_marital_status,
        ccd.cd_education_status,
        ccd.ca_city,
        ccd.ca_state,
        ccd.ca_country,
        ccd.full_address,
        sd.total_sales,
        sd.order_count
    FROM 
        CombinedCustomerData ccd
    LEFT JOIN 
        SalesData sd ON ccd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_country,
    full_address,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS order_count,
    CASE 
        WHEN COALESCE(total_sales, 0) > 1000 THEN 'High Value Customer'
        WHEN COALESCE(total_sales, 0) BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    JoinedSalesData
ORDER BY 
    total_sales DESC
LIMIT 100;
