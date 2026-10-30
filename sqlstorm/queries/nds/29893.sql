
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type) AS full_address,
        CONCAT(ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS city_state_zip,
        LENGTH(ca.ca_city) AS city_length,
        LENGTH(ca.ca_street_name) AS street_name_length
    FROM 
        customer_address ca
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
FinalReport AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.full_address,
        ad.city_state_zip,
        cs.total_sales,
        cs.total_orders,
        ad.city_length + ad.street_name_length AS address_string_length
    FROM 
        CustomerSales cs
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    JOIN AddressDetails ad ON cd.cd_demo_sk = ad.ca_address_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    AVG(total_sales) AS avg_sales,
    AVG(total_orders) AS avg_orders,
    AVG(address_string_length) AS avg_address_length
FROM 
    FinalReport
GROUP BY 
    cd_gender, cd_marital_status, cd_education_status
ORDER BY 
    cd_gender, cd_marital_status;
