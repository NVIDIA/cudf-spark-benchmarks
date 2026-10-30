
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca.ca_suite_number) ELSE '' END) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
GenderStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        SUM(ss.total_sales) AS total_sales,
        SUM(ss.order_count) AS total_orders
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesSummary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
    GROUP BY 
        cd_gender
)
SELECT 
    gs.cd_gender,
    gs.customer_count,
    gs.total_sales,
    gs.total_orders,
    CASE 
        WHEN gs.total_orders > 0 THEN gs.total_sales / gs.total_orders 
        ELSE 0
    END AS avg_sales_per_order
FROM 
    GenderStats gs
ORDER BY 
    gs.cd_gender;
