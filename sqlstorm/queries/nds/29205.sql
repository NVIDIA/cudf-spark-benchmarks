
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesData AS (
    SELECT 
        COALESCE(ws.ws_ship_date_sk, cs.cs_ship_date_sk, ss.ss_sold_date_sk) AS sale_date,
        ci.c_customer_sk,
        SUM(COALESCE(ws.ws_sales_price, cs.cs_sales_price, ss.ss_sales_price) * COALESCE(ws.ws_quantity, cs.cs_quantity, ss.ss_quantity)) AS total_sales,
        COUNT(DISTINCT COALESCE(ws.ws_order_number, cs.cs_order_number, ss.ss_ticket_number)) AS total_orders
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON ci.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON ci.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        sale_date, ci.c_customer_sk
)
SELECT 
    sale_date,
    AVG(total_sales) AS avg_sales,
    COUNT(DISTINCT c_customer_sk) AS num_customers,
    MAX(total_orders) AS max_orders,
    MIN(total_orders) AS min_orders
FROM 
    SalesData
GROUP BY 
    sale_date
ORDER BY 
    sale_date DESC
LIMIT 30;
