
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_info AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
),
return_info AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_return,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.total_sales,
    COALESCE(ri.total_return, 0) AS total_return,
    ci.total_sales - COALESCE(ri.total_return, 0) AS net_sales,
    ci.sales_rank
FROM 
    sales_info ci
LEFT JOIN 
    return_info ri ON ci.c_customer_sk = ri.sr_customer_sk
WHERE 
    (ci.total_sales > 1000 OR ci.order_count > 5) 
    AND (ci.sales_rank <= 10 OR ri.total_return IS NOT NULL)
ORDER BY 
    ci.sales_rank ASC
LIMIT 20;
