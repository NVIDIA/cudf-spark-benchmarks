
WITH RetailSales AS (
    SELECT 
        ss_item_sk, 
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
), 
WebSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales_web,
        COUNT(DISTINCT ws_order_number) AS total_transactions_web
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
SalesComparison AS (
    SELECT 
        COALESCE(r.ss_item_sk, w.ws_item_sk) AS item_sk, 
        COALESCE(r.total_sales, 0) AS store_sales,
        COALESCE(w.total_sales_web, 0) AS web_sales,
        CASE 
            WHEN COALESCE(r.total_sales, 0) = 0 THEN NULL 
            ELSE (COALESCE(w.total_sales_web, 0) - COALESCE(r.total_sales, 0)) / NULLIF(COALESCE(r.total_sales, 0), 0) 
        END AS difference_ratio
    FROM 
        RetailSales r
    FULL OUTER JOIN 
        WebSales w ON r.ss_item_sk = w.ws_item_sk
)
SELECT 
    s.item_sk,
    s.store_sales, 
    s.web_sales,
    s.difference_ratio,
    ROW_NUMBER() OVER (PARTITION BY CASE WHEN s.difference_ratio IS NULL THEN 1 ELSE 0 END ORDER BY s.difference_ratio DESC NULLS LAST) AS rank_order,
    CASE 
        WHEN s.store_sales > s.web_sales THEN 'Store dominates'
        WHEN s.web_sales > s.store_sales THEN 'Web dominates'
        ELSE 'Equal sales'
    END AS sales_analysis
FROM 
    SalesComparison s
WHERE 
    (s.store_sales > 1000 OR s.web_sales > 1000)
    AND (s.difference_ratio IS NOT NULL OR s.store_sales = s.web_sales)
ORDER BY 
    sales_analysis, rank_order;
