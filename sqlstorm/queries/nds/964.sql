
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sale_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        rs.total_net_paid
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        ranked_sales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.sale_rank <= 10
),
sales_summary AS (
    SELECT 
        ca.ca_state, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_quantity,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    t1.ca_state,
    COALESCE(t1.customer_count, 0) AS unique_customers,
    COALESCE(t1.total_quantity, 0) AS products_sold,
    COALESCE(t1.total_sales, 0) AS sales_total,
    COALESCE(t2.total_net_paid, 0) AS top_customer_spending
FROM 
    sales_summary t1
LEFT JOIN 
    (SELECT 
        ca_state,
        SUM(total_net_paid) AS total_net_paid
     FROM 
        top_customers 
     GROUP BY 
        ca_state) t2 
ON 
    t1.ca_state = t2.ca_state
ORDER BY 
    unique_customers DESC, sales_total DESC;
