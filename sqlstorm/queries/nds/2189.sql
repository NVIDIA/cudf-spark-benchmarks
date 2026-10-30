
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(COALESCE(sr_return_amt, 0)) AS total_return_value,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
ItemSalesStats AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_value,
        MAX(ws.ws_sales_price) AS max_sales_price
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
),
TopReturningCustomers AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_value
    FROM 
        CustomerReturnStats cr
    JOIN 
        customer c ON cr.c_customer_id = c.c_customer_id
    WHERE 
        cr.total_returns > (SELECT AVG(total_returns) FROM CustomerReturnStats)
    ORDER BY 
        cr.total_return_value DESC
    LIMIT 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    ts.total_sold,
    ts.total_sales_value,
    ts.max_sales_price
FROM 
    TopReturningCustomers tc
JOIN 
    ItemSalesStats ts ON ts.total_sold > 100
ORDER BY 
    tc.total_return_value DESC, ts.total_sales_value DESC;
