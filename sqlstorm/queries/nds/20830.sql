
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_net_paid, 
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rn,
        COALESCE(SUM(ws.ws_net_paid) OVER (PARTITION BY ws.ws_item_sk), 0) AS total_sales,
        CASE 
            WHEN ws.ws_net_paid IS NULL THEN 'Unknown' 
            ELSE CASE 
                WHEN ws.ws_net_paid < 20 THEN 'Low'
                WHEN ws.ws_net_paid BETWEEN 20 AND 100 THEN 'Medium'
                ELSE 'High'
            END 
        END AS sale_category
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
FilteredReturns AS (
    SELECT 
        cr.cr_item_sk, 
        SUM(cr.cr_return_quantity) AS total_returns, 
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk > 2455  
    GROUP BY 
        cr.cr_item_sk
),
JoinResults AS (
    SELECT 
        r.ws_item_sk, 
        r.ws_order_number, 
        r.ws_net_paid, 
        r.total_sales, 
        r.sale_category,
        COALESCE(f.total_returns, 0) AS total_returns,
        COALESCE(f.avg_return_amount, 0) AS avg_return_amount
    FROM 
        RankedSales r
    LEFT JOIN 
        FilteredReturns f ON r.ws_item_sk = f.cr_item_sk
    WHERE 
        r.rn = 1 OR r.total_sales > 1000
)
SELECT 
    j.ws_item_sk, 
    j.ws_order_number, 
    j.ws_net_paid, 
    j.total_sales, 
    j.sale_category,
    j.total_returns,
    CASE 
        WHEN j.total_returns > 0 THEN j.avg_return_amount / j.total_returns 
        ELSE NULL 
    END AS avg_return_per_returned_item
FROM 
    JoinResults j
ORDER BY 
    j.ws_net_paid DESC, 
    j.sale_category, 
    j.total_returns;
