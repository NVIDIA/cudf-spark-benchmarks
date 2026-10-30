
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        customer_sales
),
average_sales AS (
    SELECT 
        AVG(total_sales) AS avg_sales
    FROM 
        top_customers
    WHERE 
        sales_rank <= 100
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales'
        WHEN tc.total_sales > (SELECT avg_sales FROM average_sales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance,
    COALESCE((
        SELECT COUNT(sr_ticket_number)
        FROM store_returns sr 
        WHERE sr.sr_customer_sk = tc.c_customer_sk
    ), 0) AS return_count
FROM 
    top_customers tc
WHERE 
    tc.sales_rank <= 100
ORDER BY 
    tc.total_sales DESC;
