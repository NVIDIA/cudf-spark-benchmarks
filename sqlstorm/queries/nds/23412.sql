
WITH  customer_transactions AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(CASE 
            WHEN ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) 
            THEN ws_sales_price * ws_quantity 
            ELSE 0 
        END) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS transaction_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ct.total_sales
    FROM 
        customer c
    JOIN 
        customer_transactions ct ON c.c_customer_sk = ct.c_customer_sk
    WHERE 
        ct.transaction_rank <= 10
), sales_summary AS (
    SELECT 
        d.d_year,
        SUM(COALESCE(ws_net_paid, 0)) AS total_net_sales,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
)

SELECT 
    tc.c_first_name || ' ' || tc.c_last_name AS customer_name,
    tc.total_sales,
    ss.total_net_sales,
    ss.avg_sales_price,
    CASE 
        WHEN ss.total_orders = 0 THEN 'No Orders'
        ELSE 'Total Orders: ' || ss.total_orders
    END AS order_summary
FROM 
    top_customers tc
JOIN 
    sales_summary ss ON ss.d_year = (SELECT MAX(d_year) FROM sales_summary)
ORDER BY 
    tc.total_sales DESC, customer_name;
