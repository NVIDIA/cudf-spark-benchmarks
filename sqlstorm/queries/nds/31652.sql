
WITH  SalesTrends AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_sales_price) DESC) AS year_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
    HAVING 
        SUM(ws.ws_sales_price) > 100000
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
BestCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.order_count,
        cs.total_spent,
        CUME_DIST() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        CustomerStats cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    b.c_customer_sk,
    b.c_first_name,
    b.c_last_name,
    b.order_count,
    b.total_spent,
    st.total_sales AS yearly_sales,
    COALESCE(b.spend_rank, 0) AS spend_rank,
    CASE 
        WHEN b.spend_rank < 0.1 THEN 'Top 10%'
        ELSE 'Below Top 10%'
    END AS customer_tier
FROM 
    BestCustomers b
LEFT JOIN 
    SalesTrends st ON st.year_rank = 1
WHERE 
    b.order_count > 5
ORDER BY 
    b.total_spent DESC;
