
WITH CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca.ca_suite_number) ELSE '' END) AS full_address,
        ca.ca_city,
        ca.ca_state
    FROM customer_address ca
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN CustomerAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_ship_date_sk, ws.ws_item_sk
),
DateRange AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq
    FROM date_dim d
    WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    addr.full_address,
    addr.ca_city,
    addr.ca_state,
    dr.d_year,
    dr.d_month_seq,
    SUM(sd.total_quantity) AS total_quantity_sold,
    SUM(sd.total_sales) AS total_sales_amount
FROM CustomerInfo ci
JOIN SalesData sd ON ci.c_customer_sk = sd.ws_item_sk  
JOIN DateRange dr ON sd.ws_ship_date_sk = dr.d_date_sk
JOIN CustomerAddresses addr ON ci.full_address = addr.full_address
GROUP BY 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    addr.full_address,
    addr.ca_city,
    addr.ca_state,
    dr.d_year,
    dr.d_month_seq
ORDER BY 
    dr.d_year, 
    dr.d_month_seq, 
    total_sales_amount DESC
LIMIT 100;
