
WITH CustomerAddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        COALESCE(NULLIF(ca.ca_street_number, ''), 'N/A') AS street_number,
        COALESCE(NULLIF(ca.ca_street_name, ''), 'Unknown') AS street_name,
        CONCAT(COALESCE(NULLIF(ca.ca_street_type, ''), 'Type N/A'), ' ', COALESCE(NULLIF(ca.ca_suite_number, ''), 'Suite N/A')) AS full_address
    FROM 
        customer_address ca
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'No Dependents' 
            ELSE CONCAT(cd.cd_dep_count, ' Dependents') 
        END AS dependents_info
    FROM 
        customer_demographics cd
),
DateDetails AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        CONCAT(d.d_day_name, ' ', d.d_month_seq, '/', d.d_dom, '/', d.d_year) AS formatted_date
    FROM 
        date_dim d
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cad.ca_city,
    cad.ca_state,
    cad.ca_zip,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    dd.formatted_date,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    CustomerAddressDetails cad ON c.c_current_addr_sk = cad.ca_address_sk
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    DateDetails dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE 
    cad.ca_state IN ('CA', 'NY') 
    AND cd.cd_purchase_estimate > 500 
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, cad.ca_city, cad.ca_state, cad.ca_zip, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, dd.formatted_date
ORDER BY 
    total_sales DESC;
