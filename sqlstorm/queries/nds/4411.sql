
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(cr_order_number) AS total_returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2500000 AND 2500007
    GROUP BY 
        ws_bill_customer_sk
),
StoreSalesSummary AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_ext_sales_price) AS total_store_sales,
        COUNT(ss_ticket_number) AS total_store_orders
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 2500000 AND 2500007
    GROUP BY 
        ss_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(ws.total_sales, 0) AS total_web_sales,
    COALESCE(ss.total_store_sales, 0) AS total_store_sales,
    CASE
        WHEN COALESCE(cr.total_return_amount, 0) > 100 THEN 'High Return'
        WHEN COALESCE(ws.total_sales, 0) > 500 THEN 'High Web Sales'
        WHEN COALESCE(ss.total_store_sales, 0) > 500 THEN 'High Store Sales'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    customer c
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    WebSalesSummary ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    StoreSalesSummary ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    c.c_birth_year < 1990
ORDER BY 
    total_return_amount DESC, total_web_sales DESC, total_store_sales DESC
LIMIT 100;
