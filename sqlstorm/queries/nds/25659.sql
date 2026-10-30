
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_zip, ca_country) AS full_address
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.full_address,
        c.c_email_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_sales_amount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
TopProducts AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        sd.total_sales_quantity,
        sd.total_sales_amount
    FROM 
        item i
    JOIN 
        SalesData sd ON i.i_item_sk = sd.ws_item_sk
    ORDER BY 
        sd.total_sales_amount DESC
    LIMIT 10
)
SELECT 
    ci.full_name,
    ci.c_email_address,
    tp.i_item_id,
    tp.i_product_name,
    tp.total_sales_quantity,
    tp.total_sales_amount
FROM 
    CustomerInfo ci
CROSS JOIN 
    TopProducts tp
ORDER BY 
    ci.full_name, tp.total_sales_amount DESC;
