
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
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesOverview AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        MAX(ws_sold_date_sk) AS last_purchase_date
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
) 
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    so.total_sales,
    so.order_count,
    so.last_purchase_date,
    cd.full_address,
    cd.ca_city,
    cd.ca_state,
    cd.ca_zip
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesOverview so ON cd.c_customer_sk = so.ws_bill_customer_sk
WHERE 
    cd.cd_gender = 'M' 
    AND cd.cd_marital_status = 'S' 
    AND cd.cd_purchase_estimate >= 1000
ORDER BY 
    so.total_sales DESC
LIMIT 100;
