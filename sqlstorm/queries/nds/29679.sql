
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city, 
        ca_state, 
        ca_zip 
    FROM 
        customer_address 
    WHERE 
        ca_city ILIKE '%New%' 
        AND ca_state = 'CA'
), CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status 
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
), SaleDetails AS (
    SELECT 
        ws.ws_ship_customer_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_customer_sk, ws.ws_item_sk
), CustomerSales AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        ad.full_address,
        sd.total_quantity,
        sd.total_sales_amount
    FROM 
        CustomerDetails cd
    JOIN 
        AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    JOIN 
        SaleDetails sd ON cd.c_customer_sk = sd.ws_ship_customer_sk
)
SELECT 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name, 
    c.full_address, 
    COALESCE(c.total_quantity, 0) AS total_quantity,
    COALESCE(c.total_sales_amount, 0) AS total_sales_amount
FROM 
    CustomerSales c
ORDER BY 
    c.total_sales_amount DESC
LIMIT 100;
