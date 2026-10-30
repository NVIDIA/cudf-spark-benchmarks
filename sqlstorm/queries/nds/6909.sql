
WITH customer_data AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating,
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_country, 
        d.d_year, 
        d.d_month_seq, 
        COUNT(ws.ws_order_number) AS total_orders, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND d.d_year BETWEEN 1998 AND 2001
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating,
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_country,
        d.d_year, 
        d.d_month_seq
    HAVING 
        COUNT(ws.ws_order_number) > 0
)
SELECT 
    ca_city AS city, 
    ca_state AS state, 
    ca_country AS country, 
    EXTRACT(YEAR FROM DATE '2002-10-01') - d_year AS years_as_customer, 
    SUM(total_orders) AS total_orders,
    SUM(total_spent) AS total_revenue,
    AVG(total_spent) AS avg_spent_per_order
FROM 
    customer_data
GROUP BY 
    ca_city, 
    ca_state, 
    ca_country, 
    d_year
ORDER BY 
    total_revenue DESC 
LIMIT 10;
