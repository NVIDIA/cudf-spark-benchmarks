
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(ca_street_number) AS street_number,
        TRIM(ca_street_name) AS street_name,
        TRIM(ca_street_type) AS street_type,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ap.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts ap ON c.c_current_addr_sk = ap.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_price
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
),
FinalBenchmark AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.full_address,
        si.total_sales_quantity,
        si.total_sales_price
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON si.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    full_address,
    total_sales_quantity,
    total_sales_price,
    UPPER(full_address) AS upper_address,
    REPLACE(full_address, ' ', '_') AS address_with_underscores
FROM 
    FinalBenchmark
WHERE 
    cd_gender = 'F'
ORDER BY 
    total_sales_price DESC
LIMIT 100;
