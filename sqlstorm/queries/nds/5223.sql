
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales_amount,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_items_sold
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
merged_summary AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(cs.total_returns, 0) AS total_returns,
        COALESCE(cs.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cs.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(ss.total_sales_amount, 0) AS total_sales_amount,
        COALESCE(ss.total_orders, 0) AS total_orders,
        COALESCE(ss.total_items_sold, 0) AS total_items_sold
    FROM 
        customer_summary cs
    FULL OUTER JOIN 
        sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    m.c_customer_sk,
    m.total_returns,
    m.total_returned_quantity,
    m.total_returned_amount,
    m.total_sales_amount,
    m.total_orders,
    m.total_items_sold,
    CASE 
        WHEN m.total_sales_amount > 0 THEN (m.total_returned_amount / m.total_sales_amount) * 100
        ELSE 0
    END AS return_rate_percentage
FROM 
    merged_summary m
WHERE 
    m.total_sales_amount > 1000
ORDER BY 
    return_rate_percentage DESC;
