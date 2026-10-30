
WITH Customer_Summary AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status, c.c_first_name, c.c_last_name
),
City_Analysis AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count,
        SUM(cs.total_spent) AS total_revenue,
        AVG(cs.avg_order_value) AS average_order_value,
        RANK() OVER (ORDER BY SUM(cs.total_spent) DESC) AS revenue_rank
    FROM 
        Customer_Summary cs
    JOIN 
        customer_address ca ON cs.ca_city = ca.ca_city
    GROUP BY 
        ca.ca_city
)
SELECT 
    ca.ca_city,
    ca.customer_count,
    ca.total_revenue,
    ca.average_order_value,
    ca.revenue_rank
FROM 
    City_Analysis ca
WHERE 
    ca.customer_count > 100 AND 
    ca.average_order_value > 50.00
ORDER BY 
    ca.revenue_rank, ca.total_revenue DESC;
