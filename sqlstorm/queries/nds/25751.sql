
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_suite_number, ca_street_name, ca_street_type) AS full_address,
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
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS first_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim AS d ON c.c_first_sales_date_sk = d.d_date_sk
),
WarehouseAddress AS (
    SELECT 
        w.w_warehouse_sk,
        CONCAT_WS(' ', w.w_street_number, w.w_street_name, w.w_street_type) AS full_warehouse_address,
        w.w_city,
        w.w_state,
        w.w_zip,
        w.w_country
    FROM 
        warehouse AS w
)
SELECT 
    ac.full_address,
    ac.ca_city,
    ac.ca_state,
    ac.ca_zip,
    ac.ca_country,
    cd.full_name,
    cd.first_purchase_date,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    wa.full_warehouse_address,
    wa.w_city AS warehouse_city,
    wa.w_state AS warehouse_state,
    wa.w_zip AS warehouse_zip,
    wa.w_country AS warehouse_country
FROM 
    AddressComponents AS ac
JOIN 
    CustomerDetails AS cd ON ac.ca_address_sk = cd.c_customer_sk
JOIN 
    WarehouseAddress AS wa ON (ac.ca_state = wa.w_state AND ac.ca_city = wa.w_city)
WHERE 
    ac.ca_country = 'USA' 
    AND cd.cd_marital_status = 'M' 
    AND LENGTH(ac.full_address) > 50
ORDER BY 
    cd.first_purchase_date DESC, cd.full_name;
