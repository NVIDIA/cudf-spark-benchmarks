
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesData AS (
    SELECT 
        CASE 
            WHEN ws_ship_date_sk IS NOT NULL THEN 'Web Sale'
            WHEN cs_ship_date_sk IS NOT NULL THEN 'Catalog Sale'
            WHEN ss_sold_date_sk IS NOT NULL THEN 'Store Sale'
            ELSE 'Unknown'
        END AS sale_type,
        CASE 
            WHEN ws_ship_date_sk IS NOT NULL THEN ws_net_paid
            WHEN cs_ship_date_sk IS NOT NULL THEN cs_net_paid
            WHEN ss_sold_date_sk IS NOT NULL THEN ss_net_paid
            ELSE 0
        END AS total_sales,
        ws_bill_addr_sk AS addr_sk,
        ws_bill_customer_sk AS customer_sk
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    a.ca_country,
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    s.sale_type,
    SUM(s.total_sales) AS total_sales
FROM 
    AddressDetails a
JOIN 
    SalesData s ON a.ca_address_sk = s.addr_sk
JOIN 
    CustomerInfo c ON s.customer_sk = c.c_customer_sk
GROUP BY 
    a.full_address, a.ca_city, a.ca_state, a.ca_zip, a.ca_country, 
    c.full_name, c.cd_gender, c.cd_marital_status, 
    c.cd_education_status, s.sale_type
ORDER BY 
    total_sales DESC;
