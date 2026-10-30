
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
sales_summary AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank,
        CASE 
            WHEN cs.total_sales >= 1000 THEN 'High'
            WHEN cs.total_sales BETWEEN 500 AND 999 THEN 'Medium'
            ELSE 'Low'
        END AS sales_band
    FROM 
        customer_sales cs
),
return_summary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ss.c_customer_id,
    ss.total_sales,
    ss.total_orders,
    ss.sales_rank,
    ss.sales_band,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN rs.total_return_amount IS NULL OR rs.total_return_amount = 0 THEN 'No Returns'
        ELSE 'Returned'
    END AS return_status
FROM 
    sales_summary ss
LEFT JOIN return_summary rs ON ss.c_customer_id = rs.c_customer_id
WHERE 
    ss.total_sales > 0
ORDER BY 
    ss.sales_rank;
