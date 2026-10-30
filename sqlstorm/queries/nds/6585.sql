
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS average_order_value,
        COUNT(DISTINCT ws.ws_web_site_sk) AS purchase_channels
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
),
high_value_customers AS (
    SELECT 
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.total_spent,
        s.total_orders,
        s.average_order_value,
        s.purchase_channels
    FROM 
        sales_summary s
    WHERE 
        s.total_spent > (SELECT AVG(total_spent) FROM sales_summary)
),
customer_address_details AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_spent,
    hvc.total_orders,
    hvc.average_order_value,
    hvc.purchase_channels,
    cad.ca_city,
    cad.ca_state,
    cad.ca_country
FROM 
    high_value_customers hvc
JOIN 
    customer_address_details cad ON hvc.c_customer_sk = cad.c_customer_sk
ORDER BY 
    hvc.total_spent DESC
LIMIT 100;
