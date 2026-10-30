
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rnk
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
),
TotalRefunds AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS total_refund
    FROM
        catalog_returns cr
    WHERE
        cr.cr_return_quantity > 0
    GROUP BY
        cr.cr_item_sk
),
SalesWithRefunds AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        COALESCE(tr.total_refund, 0) AS total_refunded_amount,
        (rs.ws_sales_price - COALESCE(tr.total_refund, 0)) AS net_sales_price
    FROM 
        RankedSales rs
    LEFT JOIN 
        TotalRefunds tr ON rs.ws_item_sk = tr.cr_item_sk
    WHERE 
        rs.rnk = 1
),
FinalSales AS (
    SELECT 
        s.ws_item_sk,
        s.ws_order_number,
        s.net_sales_price,
        ROW_NUMBER() OVER (PARTITION BY s.ws_item_sk ORDER BY s.net_sales_price DESC) AS salesRank
    FROM 
        SalesWithRefunds s
    WHERE 
        s.net_sales_price > 0
    AND (SELECT COUNT(*) FROM store s2 WHERE s2.s_number_employees IS NOT NULL) > 5
)
SELECT 
    f.ws_item_sk,
    f.ws_order_number,
    f.net_sales_price,
    CASE 
        WHEN f.salesRank <= 5 THEN 'Top Sales'
        ELSE 'Other Sales'
    END AS sales_category
FROM 
    FinalSales f
WHERE 
    f.net_sales_price IS NOT NULL
UNION ALL
SELECT 
    NULL AS ws_item_sk,
    NULL AS ws_order_number,
    SUM(NULLIF(e.net_sales_price, 0)) AS total_sales_value,
    'Total Sales' AS sales_category
FROM 
    FinalSales e
WHERE 
    e.net_sales_price < 0
GROUP BY 
    e.ws_item_sk;
