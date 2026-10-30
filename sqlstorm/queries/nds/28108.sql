
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        LOWER(ca.ca_zip) AS normalized_zip
    FROM 
        customer_address ca
), CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        dd.d_date AS first_purchase_date
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON c.c_first_sales_date_sk = dd.d_date_sk
), TopCustomers AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY ad.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        CustomerDetails cd
    JOIN 
        AddressDetails ad ON cd.c_customer_id = ad.ca_address_id
)
SELECT 
    tc.full_name, 
    tc.cd_gender, 
    tc.cd_marital_status, 
    tc.full_address, 
    tc.ca_city, 
    tc.ca_state, 
    tc.cd_purchase_estimate
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 5
ORDER BY 
    tc.ca_state, tc.cd_purchase_estimate DESC;
