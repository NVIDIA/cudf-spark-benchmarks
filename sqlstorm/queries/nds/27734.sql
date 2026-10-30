
WITH AddressProcessed AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        TRIM(UPPER(ca_city)) AS normalized_city,
        CONCAT(ca_zip, ' ', ca_state) AS zip_state
    FROM 
        customer_address
),
CustomerFiltered AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ap.full_address,
        ap.normalized_city,
        ap.zip_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressProcessed ap ON c.c_current_addr_sk = ap.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > 10000 AND
        cd.cd_marital_status = 'M'
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cf.c_customer_sk,
    cf.c_first_name,
    cf.c_last_name,
    cf.normalized_city,
    cf.zip_state,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count
FROM 
    CustomerFiltered cf
LEFT JOIN 
    SalesData sd ON cf.c_customer_sk = sd.ws_bill_customer_sk
ORDER BY 
    total_sales DESC
LIMIT 100;
