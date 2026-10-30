
WITH  sales_growth AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
    HAVING 
        SUM(ws.ws_net_profit) > 1000
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING 
        COUNT(ws.ws_order_number) > 5
),
customer_details AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    d.d_year,
    SUM(sg.total_net_profit) AS year_net_profit,
    COALESCE(SUM(tc.order_count), 0) AS total_orders,
    COALESCE(SUM(tc.total_spent), 0) AS total_spent,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    sales_growth sg
LEFT JOIN 
    top_customers tc ON sg.total_net_profit > tc.total_spent
JOIN 
    customer_details cd ON tc.c_customer_id = cd.c_customer_id
JOIN 
    date_dim d ON d.d_year = sg.d_year
GROUP BY 
    d.d_year, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    d.d_year DESC, total_spent DESC;
