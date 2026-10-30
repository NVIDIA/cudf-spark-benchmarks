
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_spenders AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        ranked_customers
    WHERE 
        total_spent > 1000
),
recent_orders AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_order_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ts.c_first_name,
    ts.c_last_name,
    ts.cd_gender,
    ts.cd_marital_status,
    ro.order_count,
    ro.last_order_date,
    ts.total_spent
FROM 
    top_spenders ts
JOIN 
    recent_orders ro ON ts.c_customer_sk = ro.ws_bill_customer_sk
WHERE 
    ts.rank <= 10
ORDER BY 
    ts.total_spent DESC;
