
WITH CustomerFullName AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name
    FROM 
        customer
),
CustomerDemo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerAddress AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    cf.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_orders, 0) AS total_orders,
    COALESCE(sd.total_discount, 0) AS total_discount
FROM 
    CustomerFullName cf
LEFT JOIN 
    CustomerDemo cd ON cf.c_customer_sk = cd.c_customer_sk
LEFT JOIN 
    CustomerAddress ca ON cf.c_customer_sk = ca.c_customer_sk
LEFT JOIN 
    SalesData sd ON cf.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    cd.cd_gender = 'F'
ORDER BY 
    total_sales DESC
LIMIT 50;
