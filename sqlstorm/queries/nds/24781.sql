
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
),
FailedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_quantity,
        sr_item_sk,
        sr_customer_sk,
        sr_ticket_number,
        rg.refund_status
    FROM 
        store_returns sr
    LEFT JOIN (
        SELECT 
            cr_item_sk,
            cr_order_number,
            CASE 
                WHEN SUM(cr_return_quantity) > 0 THEN 'Partial Refund'
                ELSE 'No Refund'
            END AS refund_status
        FROM 
            catalog_returns
        GROUP BY 
            cr_item_sk, cr_order_number
    ) rg ON sr.sr_item_sk = rg.cr_item_sk AND sr.sr_ticket_number = rg.cr_order_number
    WHERE 
        sr_return_quantity > 5
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(fail.total_failed_returns, 0) AS failed_returns,
    CAST(d.d_date AS DATE) AS sales_date,
    CASE 
        WHEN cs.sales_rank <= 10 THEN 'Top 10 Customers'
        ELSE 'Regular Customers'
    END AS customer_category
FROM 
    RankedSales cs
LEFT JOIN (
    SELECT 
        sr_customer_sk,
        COUNT(sr_returned_date_sk) AS total_failed_returns
    FROM 
        FailedReturns
    GROUP BY 
        sr_customer_sk
) fail ON cs.c_customer_sk = fail.sr_customer_sk
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim) 
WHERE 
    d.d_date <= DATE('2002-10-01') - INTERVAL '1 DAY'
    AND (cs.total_sales IS NOT NULL OR fail.total_failed_returns IS NOT NULL)
ORDER BY 
    total_sales DESC, total_failed_returns ASC;
