
WITH AddressDetails AS (
    SELECT
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM
        customer_address ca
), CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ad.full_address,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        web_sales ws
    JOIN
        AddressDetails ad ON ws.ws_ship_addr_sk = ad.ca_address_sk
    JOIN
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
)
SELECT
    sd.full_name,
    sd.full_address,
    SUM(sd.ws_quantity) AS total_quantity,
    SUM(sd.ws_sales_price) AS total_sales_price,
    SUM(sd.ws_net_paid) AS total_net_paid,
    sd.cd_gender,
    sd.cd_marital_status,
    sd.cd_education_status
FROM
    SalesDetails sd
GROUP BY
    sd.full_name, sd.full_address, sd.cd_gender, sd.cd_marital_status, sd.cd_education_status
ORDER BY
    total_sales_price DESC
LIMIT 10;
