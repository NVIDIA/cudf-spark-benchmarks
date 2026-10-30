
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ad.full_address,
        ad.ca_city,
        ad.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
Orders AS (
    SELECT
        ws_sold_date_sk,
        ws_ship_date_sk,
        ws_item_sk,
        ws_bill_customer_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        CONCAT('Order ', ws_order_number) AS order_reference
    FROM 
        web_sales
),
FinalReport AS (
    SELECT
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_credit_rating,
        ci.cd_purchase_estimate,
        SUM(o.ws_quantity) AS total_quantity,
        SUM(o.ws_sales_price) AS total_sales,
        SUM(o.ws_net_profit) AS total_profit,
        COUNT(DISTINCT o.order_reference) AS total_orders
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        Orders o ON ci.c_customer_sk = o.ws_bill_customer_sk
    GROUP BY 
        ci.full_name, ci.cd_gender, ci.cd_marital_status, ci.cd_credit_rating, ci.cd_purchase_estimate
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 10000 THEN 'High Value Customer' 
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value Customer' 
        ELSE 'Low Value Customer' 
    END AS customer_value_segment
FROM 
    FinalReport
ORDER BY 
    total_profit DESC
LIMIT 50;
