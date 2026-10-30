
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
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
        CASE 
            WHEN ws_ship_date_sk IS NOT NULL THEN 'Web Sales'
            WHEN cs_ship_date_sk IS NOT NULL THEN 'Catalog Sales'
            WHEN ss_sold_date_sk IS NOT NULL THEN 'Store Sales'
            ELSE 'Unknown'
        END AS sale_type,
        c.c_customer_sk,
        COUNT(DISTINCT CASE 
            WHEN ws_order_number IS NOT NULL THEN ws_order_number 
            WHEN cs_order_number IS NOT NULL THEN cs_order_number 
            WHEN ss_ticket_number IS NOT NULL THEN ss_ticket_number 
        END) AS total_orders,
        SUM(COALESCE(ws_net_paid, 0) + COALESCE(cs_net_paid, 0) + COALESCE(ss_net_paid, 0)) AS total_spent
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
    JOIN 
        customer c ON c.c_customer_sk = COALESCE(ws.ws_bill_customer_sk, cs.cs_bill_customer_sk, ss.ss_customer_sk)
    GROUP BY 
        sale_type, c.c_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.ca_city,
    ci.ca_state,
    ss.sale_type,
    ss.total_orders,
    ss.total_spent
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesSummary ss ON ci.c_customer_sk = ss.c_customer_sk
ORDER BY 
    ci.ca_state, ss.total_spent DESC;
