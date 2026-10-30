
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c_customer_id,
        total_sales_amount,
        total_orders,
        total_quantity,
        RANK() OVER (ORDER BY total_sales_amount DESC) AS rank
    FROM 
        sales_summary
)
SELECT 
    tc.c_customer_id,
    tc.total_sales_amount,
    tc.total_orders,
    tc.total_quantity,
    ac.ca_city,
    ac.ca_state,
    ac.ca_country
FROM 
    top_customers tc
JOIN 
    customer c ON tc.c_customer_id = c.c_customer_id
JOIN 
    customer_address ac ON c.c_current_addr_sk = ac.ca_address_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_sales_amount DESC;
