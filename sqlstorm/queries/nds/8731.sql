
WITH top_customers AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
monthly_sales AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        SUM(ws.ws_sales_price * ws.ws_quantity) AS monthly_total
    FROM 
        web_sales ws 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
most_popular_items AS (
    SELECT 
        i.i_item_id, 
        SUM(ws.ws_quantity) AS total_sold
    FROM 
        item i 
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
    ORDER BY 
        total_sold DESC
    LIMIT 5
)
SELECT 
    tc.c_customer_id, 
    ms.d_year, 
    ms.d_month_seq, 
    ms.monthly_total, 
    mpi.i_item_id, 
    mpi.total_sold
FROM 
    top_customers tc 
JOIN 
    monthly_sales ms ON ms.d_year = 2023 AND ms.d_month_seq BETWEEN 1 AND 12
JOIN 
    most_popular_items mpi ON TRUE
WHERE 
    ms.monthly_total > 1000 
ORDER BY 
    tc.total_spent DESC, ms.d_year, ms.d_month_seq;
