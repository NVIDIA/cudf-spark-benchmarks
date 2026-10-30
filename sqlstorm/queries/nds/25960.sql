
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_suite_number, ca_street_name, ca_street_type, ca_city, ca_state, ca_zip, ca_country)) AS full_address
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_item_sk) AS items_sold,
        ws.ws_bill_customer_sk
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number, ws.ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    sd.total_sales,
    sd.items_sold,
    ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS rank
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesDetails sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    cd.cd_gender = 'F' AND
    cd.cd_marital_status = 'M'
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
