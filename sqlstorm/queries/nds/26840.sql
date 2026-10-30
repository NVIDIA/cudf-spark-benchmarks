
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerNames AS (
    SELECT 
        c_customer_sk,
        TRIM(c_first_name) AS first_name,
        TRIM(c_last_name) AS last_name,
        CONCAT(TRIM(c_first_name), ' ', TRIM(c_last_name)) AS full_name
    FROM 
        customer
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cn.full_name,
    ac.full_address,
    ac.ca_city,
    ac.ca_state,
    ac.ca_zip,
    ac.ca_country,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count
FROM 
    CustomerNames cn
JOIN 
    customer_address ca ON ca.ca_address_sk = cn.c_customer_sk
JOIN 
    AddressComponents ac ON ac.ca_address_sk = ca.ca_address_sk
LEFT JOIN 
    SalesData sd ON sd.ws_bill_customer_sk = cn.c_customer_sk
WHERE 
    ac.ca_country = 'USA'
ORDER BY 
    total_sales DESC, 
    full_name ASC
LIMIT 100;
