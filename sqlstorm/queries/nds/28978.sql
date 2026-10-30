
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state 
    FROM 
        customer_address 
    WHERE 
        ca_city IS NOT NULL AND ca_state IS NOT NULL
),
CustomerGender AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender_label
    FROM 
        customer_demographics 
),
CustomerLocation AS (
    SELECT 
        c.c_customer_sk,
        a.full_address,
        a.ca_city,
        a.ca_state,
        g.gender_label 
    FROM 
        customer c
    JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        CustomerGender g ON c.c_current_cdemo_sk = g.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_addr_sk
),
CustomerSales AS (
    SELECT 
        cl.c_customer_sk,
        cl.full_address,
        cl.ca_city,
        cl.ca_state,
        cl.gender_label,
        COALESCE(ss.total_sales, 0) AS total_sales,
        ss.total_orders
    FROM 
        CustomerLocation cl
    LEFT JOIN 
        SalesSummary ss ON cl.c_customer_sk = ss.ws_bill_addr_sk
)
SELECT 
    ca_city,
    ca_state,
    gender_label,
    COUNT(c_customer_sk) AS customer_count,
    SUM(total_sales) AS aggregate_sales,
    AVG(total_sales) AS average_sales_per_customer
FROM 
    CustomerSales
GROUP BY 
    ca_city, ca_state, gender_label
ORDER BY 
    aggregate_sales DESC, customer_count DESC;
