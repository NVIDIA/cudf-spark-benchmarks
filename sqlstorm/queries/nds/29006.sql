
WITH Address_Concat AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', 
            ca_street_number, 
            ca_street_name, 
            ca_street_type, 
            ca_suite_number, 
            ca_city, 
            ca_state, 
            ca_zip, 
            ca_country) AS full_address
    FROM 
        customer_address
),
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ad.full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        Address_Concat ad ON c.c_current_addr_sk = ad.ca_address_sk
),
Date_Range AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_year
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
),
Sales_Summary AS (
    SELECT 
        w.ws_bill_customer_sk,
        SUM(w.ws_net_paid) AS total_sales,
        COUNT(w.ws_order_number) AS total_orders
    FROM 
        web_sales w
    JOIN 
        Date_Range dr ON w.ws_sold_date_sk = dr.d_date_sk
    GROUP BY 
        w.ws_bill_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.full_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    ss.total_sales,
    ss.total_orders
FROM 
    Customer_Info ci
LEFT JOIN 
    Sales_Summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
ORDER BY 
    ss.total_sales DESC NULLS LAST
LIMIT 100;
