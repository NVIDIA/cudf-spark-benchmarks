WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS return_customers
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk >= (SELECT d.d_date_sk 
                                     FROM date_dim d 
                                     WHERE d.d_date = cast('2002-10-01' as date) - INTERVAL '1 year')
    GROUP BY 
        cr.cr_item_sk
),
StoreSalesDetails AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    ia.i_item_id,
    ia.i_product_name,
    COALESCE(total_sales.total_quantity, 0) AS total_store_quantity,
    COALESCE(total_sales.total_net_paid, 0) AS total_sales_amount,
    ranked.rank,
    COALESCE(customer_returns.total_returned, 0) AS total_returns,
    COALESCE(customer_returns.return_customers, 0) AS num_returning_customers,
    CASE 
        WHEN COALESCE(customer_returns.total_returned, 0) > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    item ia 
LEFT JOIN 
    StoreSalesDetails total_sales ON ia.i_item_sk = total_sales.ss_item_sk
LEFT JOIN 
    CustomerReturns customer_returns ON ia.i_item_sk = customer_returns.cr_item_sk
LEFT JOIN 
    RankedSales ranked ON ia.i_item_sk = ranked.ws_item_sk AND ranked.rank = 1
WHERE 
    ia.i_current_price > 20.00 
    AND (customer_returns.total_returned IS NULL OR customer_returns.total_returned < 10)
ORDER BY 
    total_sales.total_net_paid DESC,
    total_returns DESC;