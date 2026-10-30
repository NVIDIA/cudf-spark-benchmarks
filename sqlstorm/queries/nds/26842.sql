
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca.ca_suite_number), '')) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        LENGTH(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', 
                      ca.ca_street_type, COALESCE(CONCAT(' Suite ', ca.ca_suite_number), ''))) AS address_length
    FROM 
        customer_address ca
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        (ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        ws.ws_bill_customer_sk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT DISTINCT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
)
SELECT 
    CONCAT(cd.full_name, ' - ', ad.full_address) AS customer_address_info,
    SUM(sd.total_sales) AS total_spent,
    ad.address_length AS address_length
FROM 
    CustomerDetails cd
JOIN 
    AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
JOIN 
    SalesDetails sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
GROUP BY 
    cd.full_name, ad.full_address, ad.address_length
HAVING 
    SUM(sd.total_sales) > 1000
ORDER BY 
    total_spent DESC;
