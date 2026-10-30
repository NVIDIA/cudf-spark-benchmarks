
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(', ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
), 
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
Demographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ci.total_sales,
        ci.order_count,
        addr.full_address,
        addr.ca_city,
        addr.ca_state,
        addr.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        SalesInfo ci ON c.c_customer_sk = ci.customer_sk
    JOIN 
        AddressInfo addr ON c.c_current_addr_sk = addr.ca_address_sk
)
SELECT 
    d.c_first_name,
    d.c_last_name,
    d.cd_gender,
    d.cd_marital_status,
    d.total_sales,
    d.order_count,
    CONCAT(d.ca_city, ', ', d.ca_state, ' ', d.ca_zip) AS full_location
FROM 
    Demographics d
WHERE 
    d.total_sales > 1000
ORDER BY 
    d.total_sales DESC;
