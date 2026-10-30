
WITH  sales_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_sale,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022 AND d_moy = 12 LIMIT 1)
                                AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2022 AND d_moy = 12 ORDER BY d_date DESC LIMIT 1)
    GROUP BY 
        c.c_customer_sk
),
ranked_sales AS (
    SELECT 
        s.c_customer_sk,
        s.total_sale,
        s.total_orders,
        CASE 
            WHEN s.rank <= 10 THEN 'Top 10 Customers'
            WHEN s.rank BETWEEN 11 AND 50 THEN 'Top 50 Customers'
            ELSE 'Other Customers'
        END AS customer_segment
    FROM 
        sales_summary s
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(r.total_sale, 0) AS total_sale,
    COALESCE(r.total_orders, 0) AS total_orders,
    r.customer_segment
FROM 
    customer c
LEFT JOIN 
    ranked_sales r ON c.c_customer_sk = r.c_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
    AND c.c_current_addr_sk IS NOT NULL
ORDER BY 
    total_sale DESC
LIMIT 100;
