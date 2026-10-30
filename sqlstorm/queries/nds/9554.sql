
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(cr.cr_return_quantity) AS total_returned_items,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM
        customer c
    JOIN
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
PromotionsApplied AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales,
        SUM(ws.ws_sales_price - ws.ws_ext_discount_amt) AS net_sales
    FROM
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerSummary AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        COALESCE(cr.total_returned_items, 0) AS total_returned_items,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        pa.total_sales,
        pa.net_sales
    FROM 
        CustomerReturns cr
    LEFT JOIN 
        PromotionsApplied pa ON cr.c_customer_sk = pa.ws_bill_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_returned_items,
    cs.total_return_amount,
    cs.total_sales,
    cs.net_sales,
    COALESCE(cs.total_return_amount / NULLIF(cs.total_sales, 0), 0) AS return_to_sales_ratio
FROM 
    CustomerSummary cs
ORDER BY 
    return_to_sales_ratio DESC
LIMIT 10;
