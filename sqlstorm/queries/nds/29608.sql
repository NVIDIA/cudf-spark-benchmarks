
WITH AddressCounts AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) AS address_count 
    FROM 
        customer_address 
    GROUP BY 
        ca_city, 
        ca_state
),
MaxAddress AS (
    SELECT 
        ca_city, 
        ca_state 
    FROM 
        AddressCounts 
    WHERE 
        address_count = (SELECT MAX(address_count) FROM AddressCounts)
),
CustomerStats AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ca.ca_city, 
        ca.ca_state, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
        SUM(ws.ws_sales_price) AS total_spent 
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ca.ca_city, ca.ca_state
)
SELECT 
    cs.c_customer_id, 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_orders,
    cs.total_spent,
    'Highest City' AS address_type,
    mc.ca_city,
    mc.ca_state 
FROM 
    CustomerStats cs 
JOIN 
    MaxAddress mc ON cs.ca_city = mc.ca_city AND cs.ca_state = mc.ca_state
WHERE 
    cs.total_spent > 1000
ORDER BY 
    cs.total_spent DESC;
