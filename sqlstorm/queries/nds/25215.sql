
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
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ad.full_address AS customer_address
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesData AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        ci.customer_name,
        ci.customer_address,
        dd.d_date,
        dd.d_month_seq,
        dd.d_year
    FROM 
        catalog_sales cs
    JOIN 
        CustomerInfo ci ON cs.cs_bill_customer_sk = ci.c_customer_sk
    JOIN 
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
)
SELECT 
    customer_name,
    COUNT(DISTINCT cs_order_number) AS total_orders,
    SUM(cs_quantity) AS total_quantity,
    ROUND(SUM(cs_net_paid), 2) AS total_amount_spent,
    ROUND(AVG(cs_net_profit), 2) AS average_profit,
    MIN(d_date) AS first_purchase_date,
    MAX(d_date) AS last_purchase_date
FROM 
    SalesData
GROUP BY 
    customer_name
HAVING 
    COUNT(DISTINCT cs_order_number) > 5
ORDER BY 
    total_amount_spent DESC;
