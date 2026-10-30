
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        ss.total_sales,
        ss.avg_profit,
        ss.order_count,
        ss.last_purchase_date
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.c_customer_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    ORDER BY 
        ss.total_sales DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.avg_profit,
    tc.order_count,
    tc.last_purchase_date,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ca.ca_city,
    ca.ca_state
FROM 
    top_customers tc
JOIN 
    customer c ON tc.c_customer_id = c.c_customer_id
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    cd.cd_gender = 'F'
AND 
    tc.total_sales > 1000
ORDER BY 
    tc.last_purchase_date DESC;
