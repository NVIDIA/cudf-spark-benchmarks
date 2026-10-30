
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax
    FROM 
        customer c
    JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesStats AS (
    SELECT 
        c.c_customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    cs.c_customer_id,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(cr.total_return_amt_inc_tax, 0) AS total_return_amt_inc_tax,
    CASE 
        WHEN COALESCE(cs.total_sales, 0) > 0 THEN 
            (COALESCE(cr.total_return_amt_inc_tax, 0) / cs.total_sales) * 100 
        ELSE 
            0 
    END AS return_rate_percentage
FROM 
    SalesStats cs
FULL OUTER JOIN 
    CustomerReturnStats cr ON cs.c_customer_id = cr.c_customer_id
ORDER BY 
    return_rate_percentage DESC
LIMIT 100;
