
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(CASE WHEN sr_return_quantity > 0 THEN sr_return_quantity ELSE 0 END) AS total_return_quantity,
        SUM(CASE WHEN sr_return_amt > 0 THEN sr_return_amt ELSE 0 END) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    JOIN 
        customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales_amt,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(sd.total_sales_amt, 0) AS total_sales_amt,
        COALESCE(sd.order_count, 0) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_id = cr.c_customer_id
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    total_return_quantity,
    total_return_amt,
    total_sales_amt,
    order_count,
    CASE 
        WHEN total_sales_amt = 0 THEN 0 
        ELSE (total_return_amt / total_sales_amt) * 100 
    END AS return_rate_percentage
FROM 
    CombinedData
ORDER BY 
    return_rate_percentage DESC
LIMIT 10;
