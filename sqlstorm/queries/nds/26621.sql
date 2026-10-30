
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS address_rank
    FROM 
        customer_address
), 
DemographicDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
), 
PurchaseSummary AS (
    SELECT 
        dd.c_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        DemographicDetails dd ON ws.ws_bill_customer_sk = dd.c_customer_sk
    GROUP BY 
        dd.c_customer_sk
)
SELECT 
    dd.c_customer_sk,
    dd.c_first_name,
    dd.c_last_name,
    dd.cd_gender,
    dd.cd_marital_status,
    dd.cd_education_status,
    ps.total_quantity,
    ps.total_sales,
    CONCAT(dd.ca_city, ', ', dd.ca_state, ' ', dd.ca_zip) AS full_location
FROM 
    DemographicDetails dd
LEFT JOIN 
    PurchaseSummary ps ON dd.c_customer_sk = ps.c_customer_sk
WHERE 
    dd.cd_gender = 'F' 
    AND dd.cd_purchase_estimate > 1000
ORDER BY 
    ps.total_sales DESC;
