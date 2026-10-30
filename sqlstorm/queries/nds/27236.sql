
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
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender, 
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_sales_value
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
DetailedSales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity_sold,
        s.total_sales_value,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        i.i_current_price
    FROM 
        SalesDetails s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    s.total_quantity_sold,
    s.total_sales_value,
    s.i_product_name,
    s.i_brand,
    s.i_category,
    s.i_current_price
FROM 
    CustomerDetails c
JOIN 
    AddressDetails a ON c.c_customer_sk = a.ca_address_sk
JOIN 
    DetailedSales s ON c.c_customer_sk = s.ws_item_sk
WHERE 
    c.cd_gender = 'M' 
    AND s.total_sales_value > 1000 
    AND s.i_category = 'Electronics'
ORDER BY 
    s.total_sales_value DESC
LIMIT 100;
