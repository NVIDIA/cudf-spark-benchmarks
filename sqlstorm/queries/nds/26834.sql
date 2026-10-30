
WITH AddressConcat AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
CustomerGender AS (
    SELECT 
        c_customer_sk,
        cd_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    a.full_address,
    g.cd_gender,
    COALESCE(sd.total_sales, 0) AS total_sales
FROM 
    AddressConcat a
JOIN 
    CustomerGender g ON a.ca_address_sk = g.c_customer_sk
LEFT JOIN 
    SalesData sd ON g.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    g.cd_gender IS NOT NULL
ORDER BY 
    total_sales DESC
LIMIT 10;
