
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status
),
OrderStats AS (
    SELECT
        ci.customer_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.total_orders,
        ci.total_spent,
        ROW_NUMBER() OVER (PARTITION BY ci.ca_city ORDER BY ci.total_spent DESC) AS rank_within_city
    FROM 
        CustomerInfo ci
)
SELECT 
    os.customer_name,
    os.ca_city,
    os.ca_state,
    os.cd_gender,
    os.cd_marital_status,
    os.total_orders,
    os.total_spent
FROM 
    OrderStats os
WHERE 
    os.rank_within_city <= 10
ORDER BY 
    os.ca_city, os.total_spent DESC;
