
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
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales_value,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    a.ca_country,
    s.total_quantity_sold,
    s.total_sales_value,
    s.total_profit,
    CONCAT('Sales in ', a.ca_city, ', ', a.ca_state, ' amounting to ', CAST(s.total_sales_value AS STRING), ' with a total quantity of ', s.total_quantity_sold) AS sales_summary
FROM 
    CustomerDetails c
JOIN 
    AddressDetails a ON c.c_customer_sk = a.ca_address_sk
LEFT JOIN 
    SalesData s ON c.c_customer_sk = s.ws_item_sk
WHERE 
    c.cd_gender = 'M' AND 
    c.cd_marital_status = 'S'
ORDER BY 
    s.total_sales_value DESC
LIMIT 100;
