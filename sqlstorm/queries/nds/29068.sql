
WITH CustomerAddressData AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca.ca_suite_number) END, 
               ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        ca.ca_country,
        ca.ca_gmt_offset
    FROM 
        customer_address ca
),
CustomerDemographicsData AS (
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
CustomerAndAddress AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cad.full_address,
        cad.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        CustomerAddressData cad ON c.c_current_addr_sk = cad.ca_address_sk
    JOIN 
        CustomerDemographicsData cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DateInfo AS (
    SELECT 
        d.d_date,
        d.d_month_seq,
        d.d_year,
        d.d_date_sk
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
SalesInfo AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        DateInfo di ON ws.ws_sold_date_sk = di.d_date_sk
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ca.c_first_name,
    ca.c_last_name,
    ca.full_address,
    ca.ca_country,
    ca.cd_gender,
    ca.cd_marital_status,
    si.total_quantity_sold,
    si.total_sales
FROM 
    CustomerAndAddress ca
LEFT JOIN 
    SalesInfo si ON ca.c_customer_sk = si.ws_item_sk
ORDER BY 
    si.total_sales DESC
LIMIT 100;
