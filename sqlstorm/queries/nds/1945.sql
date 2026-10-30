
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS revenue_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
return_stats AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
final_report AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        tc.order_count,
        COALESCE(rs.return_count, 0) AS return_count,
        COALESCE(rs.total_return_amt, 0) AS total_return_amt
    FROM 
        top_customers tc
    LEFT JOIN 
        return_stats rs ON tc.c_customer_sk = rs.sr_customer_sk
    WHERE 
        tc.revenue_rank <= 10
)
SELECT 
    fr.c_first_name,
    fr.c_last_name,
    fr.total_sales,
    fr.order_count,
    fr.return_count,
    fr.total_return_amt,
    (fr.total_sales - fr.total_return_amt) AS net_revenue
FROM 
    final_report fr
ORDER BY 
    net_revenue DESC;
