
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
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
    c.customer_name,
    c.cd_gender,
    c.cd_marital_status,
    c.full_address,
    c.ca_city,
    c.ca_state,
    c.ca_zip,
    s.total_sales,
    s.order_count,
    CASE 
        WHEN s.total_sales IS NOT NULL THEN 
            CASE 
                WHEN s.total_sales > 1000 THEN 'High'
                WHEN s.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
                ELSE 'Low'
            END
        ELSE 'No Sales'
    END AS sales_category
FROM 
    CustomerInfo c
LEFT JOIN 
    SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
ORDER BY 
    sales_category DESC, c.customer_name ASC;
