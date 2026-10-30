
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_street_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_street_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        dw.d_date AS first_purchase_date
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressComponents ad ON c.c_current_addr_sk = ad.ca_address_sk
    LEFT JOIN 
        (SELECT MIN(d_date) as d_date, c_first_sales_date_sk
         FROM
             date_dim dd
         JOIN
             customer c2 ON c2.c_first_sales_date_sk = dd.d_date_sk
         GROUP BY c2.c_first_sales_date_sk) dw ON c.c_first_sales_date_sk = dw.c_first_sales_date_sk
), 
SalesData AS (
    SELECT 
        ws_ship_addr_sk,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY ws_ship_addr_sk
)
SELECT 
    cd.full_customer_name,
    cd.cd_gender,
    cd.cd_marital_status,
    sd.total_quantity,
    sd.order_count,
    cd.full_street_address,
    cd.ca_city,
    cd.ca_state,
    cd.ca_zip,
    cd.first_purchase_date
FROM 
    CustomerDetails cd
JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_ship_addr_sk
WHERE 
    cd.cd_gender = 'F'
ORDER BY 
    sd.total_quantity DESC, 
    cd.first_purchase_date ASC
LIMIT 50;
