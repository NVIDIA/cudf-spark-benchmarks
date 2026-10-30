
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2451915 AND 2451916
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_current_addr_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
TopCustomers AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        sd.total_sales,
        sd.order_count,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        ai.ca_country
    FROM 
        SalesData sd
    JOIN 
        CustomerInfo ci ON sd.ws_bill_customer_sk = ci.c_customer_sk
    LEFT JOIN 
        AddressInfo ai ON ci.c_current_addr_sk = ai.ca_address_sk
    WHERE 
        sd.sales_rank <= 10
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_sales,
    order_count,
    COALESCE(ca_city, 'Unknown') AS city,
    COALESCE(ca_state, 'Unknown') AS state,
    COALESCE(ca_zip, '00000') AS zip,
    COALESCE(ca_country, 'Unknown') AS country
FROM 
    TopCustomers
ORDER BY 
    total_sales DESC;
