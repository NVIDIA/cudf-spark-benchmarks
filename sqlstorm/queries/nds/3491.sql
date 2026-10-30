
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        AVG(sr.sr_return_quantity) AS avg_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
ItemSalesStats AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold_quantity,
        SUM(ws.ws_sales_price) AS total_sales_amount
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231 
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    c.c_customer_id,
    cs.total_returns,
    cs.total_return_amount,
    cs.avg_return_quantity,
    iss.total_sold_quantity,
    iss.total_sales_amount,
    CASE 
        WHEN cs.total_returns IS NULL THEN 'No Returns'
        ELSE 'Returns Found'
    END AS return_status,
    CASE 
        WHEN iss.total_sales_amount > 0 
        THEN ROUND((cs.total_return_amount / iss.total_sales_amount) * 100, 2) 
        ELSE 0 
    END AS return_percentage
FROM 
    CustomerReturnStats cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    ItemSalesStats iss ON iss.ws_item_sk IN (SELECT DISTINCT cr.cr_item_sk FROM catalog_returns cr WHERE cr.cr_returning_customer_sk = c.c_customer_sk)
WHERE 
    cs.total_returns > 0 OR iss.total_sold_quantity IS NOT NULL
ORDER BY 
    return_percentage DESC;
