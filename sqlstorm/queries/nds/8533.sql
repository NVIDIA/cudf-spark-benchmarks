
WITH customer_data AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        ca.ca_city, 
        ca.ca_state,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND ca.ca_state IN ('NY', 'CA')
        AND ws.ws_sold_date_sk BETWEEN 2455000 AND 2456000
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        ca.ca_city, 
        ca.ca_state
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS sales_rank
    FROM 
        customer_data
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    c.ca_city, 
    c.ca_state, 
    c.total_sales 
FROM 
    top_customers c
WHERE 
    c.sales_rank <= 10 
ORDER BY 
    c.ca_state, 
    c.total_sales DESC;
