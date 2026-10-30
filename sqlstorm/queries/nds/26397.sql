
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
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        cs.cs_order_number,
        ws.ws_ship_mode_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_order_number ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        catalog_sales cs
        JOIN web_sales ws ON cs.cs_order_number = ws.ws_order_number
),
RankedSales AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        sd.cs_order_number,
        sd.ws_ship_mode_sk,
        sd.ws_sales_price,
        sd.sales_rank
    FROM 
        CustomerInfo ci
        JOIN SalesData sd ON ci.c_customer_sk = sd.cs_order_number
)
SELECT
    full_name,
    ca_city,
    ca_state,
    COUNT(cs_order_number) AS total_orders,
    AVG(ws_sales_price) AS avg_sale_price,
    MAX(sales_rank) AS highest_sale_rank
FROM 
    RankedSales
WHERE 
    ca_state IN ('NY', 'CA')
GROUP BY 
    full_name, ca_city, ca_state
HAVING 
    COUNT(cs_order_number) > 5
ORDER BY 
    avg_sale_price DESC, total_orders DESC;
