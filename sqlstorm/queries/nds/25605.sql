
WITH AddressInfo AS (
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
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
RecentSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        ci.full_name,
        ai.full_address,
        rs.total_sales,
        rs.total_orders
    FROM 
        RecentSales rs
    JOIN 
        CustomerInfo ci ON rs.ws_bill_customer_sk = ci.c_customer_sk
    JOIN 
        AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
    WHERE 
        rs.total_sales > 1000
)
SELECT 
    full_name,
    full_address,
    total_sales,
    total_orders
FROM 
    TopCustomers
ORDER BY 
    total_sales DESC
LIMIT 10;
