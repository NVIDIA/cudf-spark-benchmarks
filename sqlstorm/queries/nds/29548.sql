
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        SUBSTRING(ca_city, 1, 5) AS city_prefix,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        dd.d_year AS birth_year
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON c.c_birth_year = dd.d_year
),
SalesDetails AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_item_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    ad.full_address,
    sd.total_quantity,
    sd.total_sales
FROM 
    CustomerDetails cd
LEFT JOIN 
    AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
LEFT JOIN 
    SalesDetails sd ON cd.c_customer_sk = sd.ws_ship_date_sk
WHERE 
    ad.ca_country = 'USA' 
    AND cd.cd_gender = 'F'
    AND sd.total_sales > 1000
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
