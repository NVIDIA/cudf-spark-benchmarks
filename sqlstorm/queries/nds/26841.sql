
WITH CustomerAddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
CustomerDemographicsDetails AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
),
HistoricalSalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sales_price) AS max_sale_price,
        MIN(ws.ws_sales_price) AS min_sale_price
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    cad.full_address,
    cad.ca_city,
    cad.ca_state,
    cad.ca_zip,
    cad.ca_country,
    cd.cd_gender,
    cd.cd_marital_status,
    hsd.total_sales,
    hsd.order_count,
    hsd.max_sale_price,
    hsd.min_sale_price
FROM 
    customer c
JOIN 
    CustomerAddressDetails cad ON c.c_current_addr_sk = cad.ca_address_sk
JOIN 
    CustomerDemographicsDetails cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    HistoricalSalesData hsd ON c.c_customer_sk = hsd.ws_bill_customer_sk
WHERE 
    cad.ca_city LIKE 'San%'
AND 
    cd.cd_marital_status = 'S'
ORDER BY 
    hsd.total_sales DESC
LIMIT 50;
