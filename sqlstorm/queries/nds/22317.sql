
WITH CustomerReturns AS (
    SELECT
        CASE 
            WHEN sr_return_quantity IS NULL THEN 0 
            ELSE sr_return_quantity 
        END AS total_return_qty,
        sr_item_sk,
        sr_customer_sk,
        sr_returned_date_sk,
        sr_reason_sk
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
        AND sr_ticket_number IS NOT NULL
),
ReturnReasons AS (
    SELECT
        r.r_reason_sk,
        COUNT(*) AS reason_count
    FROM 
        CustomerReturns cr
    JOIN 
        reason r ON cr.sr_reason_sk = r.r_reason_sk
    GROUP BY 
        r.r_reason_sk
),
SalesDetails AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(cr.total_return_qty, 0) AS total_return_qty,
    COUNT(rr.r_reason_sk) AS num_return_reasons
FROM 
    item i 
LEFT JOIN 
    SalesDetails sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
LEFT JOIN 
    ReturnReasons rr ON rr.r_reason_sk = cr.sr_reason_sk
WHERE 
    (sd.total_sales IS NULL OR sd.total_sales < 5000) 
    AND COALESCE(cr.total_return_qty, 0) > (SELECT AVG(total_return_qty) FROM CustomerReturns)
GROUP BY 
    i.i_item_id, 
    i.i_item_desc, 
    sd.total_sales,
    cr.total_return_qty
HAVING 
    COUNT(DISTINCT rr.r_reason_sk) > 2
ORDER BY 
    total_sales DESC, 
    num_return_reasons ASC
LIMIT 10;
