
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_quantity_returned,
        SUM(COALESCE(sr_return_amt, 0)) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_value,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
AggregateData AS (
    SELECT 
        cr.c_customer_id,
        COALESCE(sd.total_orders, 0) AS total_orders,
        COALESCE(sd.total_sales_value, 0) AS total_sales_value,
        cr.total_quantity_returned,
        cr.total_return_amount,
        cr.return_count,
        CASE
            WHEN sd.total_sales_value > 0 THEN 
                (cr.total_return_amount / sd.total_sales_value) * 100
            ELSE 
                0 
        END AS return_percentage
    FROM 
        CustomerReturns cr
    LEFT JOIN 
        SalesData sd ON cr.c_customer_id = CAST(sd.ws_bill_customer_sk AS CHAR(16))
)
SELECT 
    ad.c_customer_id,
    ad.total_orders,
    ad.total_sales_value,
    ad.total_quantity_returned,
    ad.total_return_amount,
    ad.return_count,
    ad.return_percentage,
    (ROW_NUMBER() OVER (ORDER BY ad.return_percentage DESC)) AS rank
FROM 
    AggregateData ad
WHERE 
    ad.return_percentage > 0
ORDER BY 
    ad.return_percentage DESC
LIMIT 10;

