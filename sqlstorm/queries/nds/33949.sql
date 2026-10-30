
WITH  sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        d.d_year,
        d.d_month_seq,
        RANK() OVER (PARTITION BY d.d_year ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year IN (2022, 2023)
),
top_sales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_ext_sales_price) AS total_sales
    FROM 
        sales_data sd
    WHERE 
        sd.sales_rank <= 10
    GROUP BY 
        sd.ws_item_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ca.ca_city AS customer_city,
    cs.order_count,
    cs.total_spent,
    ts.total_quantity,
    ts.total_sales 
FROM 
    customer_sales cs
LEFT JOIN 
    top_sales ts ON cs.order_count > 5
LEFT JOIN 
    customer_address ca ON cs.c_customer_sk = ca.ca_address_sk
WHERE 
    cs.total_spent > (SELECT AVG(cs2.total_spent) FROM customer_sales cs2)
ORDER BY 
    cs.total_spent DESC
LIMIT 50;
