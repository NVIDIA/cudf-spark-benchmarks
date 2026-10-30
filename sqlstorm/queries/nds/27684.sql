
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country,
        ca_address_sk
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        c.c_current_addr_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        c.c_customer_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    CONCAT(cu.full_name, ' from ', ad.full_address) AS customer_info,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    cs.total_orders,
    cs.total_sales,
    cs.total_profit,
    CASE 
        WHEN cs.total_sales > 1000 THEN 'High Value Customer'
        WHEN cs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM 
    CustomerDetails cu
JOIN 
    AddressDetails ad ON cu.c_current_addr_sk = ad.ca_address_sk
JOIN 
    SalesSummary cs ON cu.c_customer_sk = cs.ws_bill_customer_sk
WHERE 
    ad.ca_state = 'CA'
ORDER BY 
    cs.total_sales DESC
LIMIT 100;
