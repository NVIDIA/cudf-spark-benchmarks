
WITH customer_purchase_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), high_value_customers AS (
    SELECT 
        * 
    FROM 
        customer_purchase_summary
    WHERE 
        total_spent > 1000
), customer_addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
), customer_demo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer_demographics cd
    JOIN 
        high_value_customers hvc ON hvc.c_customer_sk = cd.cd_demo_sk
), customer_info AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.total_orders,
        hvc.total_spent,
        hvc.avg_order_value,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        high_value_customers hvc
    JOIN 
        customer_addresses ca ON ca.ca_address_sk = hvc.c_customer_sk
    JOIN 
        customer_demo cd ON cd.cd_demo_sk = hvc.c_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.total_orders,
    ci.total_spent,
    ci.avg_order_value,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ci.cd_gender,
    ci.cd_marital_status
FROM 
    customer_info ci
ORDER BY 
    ci.total_spent DESC
LIMIT 50;
