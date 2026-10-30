
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
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
        dem.cd_gender,
        dem.cd_marital_status,
        dem.cd_purchase_estimate,
        dem.cd_credit_rating,
        addr.full_address,
        addr.ca_city,
        addr.ca_state,
        addr.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics dem ON c.c_current_cdemo_sk = dem.cd_demo_sk
    JOIN 
        AddressParts addr ON c.c_current_addr_sk = addr.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
)
SELECT 
    date_dim.d_date AS sale_date,
    sales.total_sales,
    sales.total_orders,
    sales.unique_customers,
    COUNT(DISTINCT cust.c_customer_sk) AS total_customers
FROM 
    date_dim
JOIN 
    SalesData sales ON date_dim.d_date_sk = sales.ws_sold_date_sk
LEFT JOIN 
    CustomerInfo cust ON cust.customer_name IS NOT NULL
WHERE 
    date_dim.d_year = 2023
GROUP BY 
    date_dim.d_date, sales.total_sales, sales.total_orders, sales.unique_customers
ORDER BY 
    date_dim.d_date;
