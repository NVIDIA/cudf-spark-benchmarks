
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
), CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(TRIM(c_salutation), ' ', TRIM(c_first_name), ' ', TRIM(c_last_name)) AS full_name,
        c_email_address,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), RecentOrders AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim) 
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.c_email_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    COALESCE(ro.total_spent, 0) AS total_spent,
    COALESCE(ro.order_count, 0) AS order_count
FROM 
    CustomerDetails cd
JOIN 
    AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
LEFT JOIN 
    RecentOrders ro ON cd.c_customer_sk = ro.ws_bill_customer_sk
WHERE 
    cd.cd_gender = 'F'
ORDER BY 
    total_spent DESC
LIMIT 100;
