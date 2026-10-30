
WITH  SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 12
        )
    GROUP BY 
        ws_item_sk
),
TopPerformers AS (
    SELECT 
        ss.ws_item_sk,
        i.i_item_desc,
        ss.total_quantity,
        ss.total_sales,
        CASE 
            WHEN i.i_current_price IS NOT NULL THEN ROUND(ss.total_sales / NULLIF(ss.total_quantity, 0), 2)
            ELSE 0
        END AS average_sales_price
    FROM 
        SalesSummary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    WHERE 
        ss.sales_rank <= 10
),
CustomerReturnStatistics AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
FinalAnalysis AS (
    SELECT 
        tp.ws_item_sk,
        tp.i_item_desc,
        tp.total_quantity,
        tp.total_sales,
        tp.average_sales_price,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN cr.return_count > 0 THEN (tp.total_sales - cr.total_return_amt) / NULLIF(tp.total_sales, 0)
            ELSE 1.0
        END AS net_sales_ratio
    FROM 
        TopPerformers tp
    LEFT JOIN 
        CustomerReturnStatistics cr ON tp.ws_item_sk = cr.sr_item_sk
)
SELECT 
    fa.ws_item_sk,
    fa.i_item_desc,
    fa.total_quantity,
    fa.total_sales,
    fa.average_sales_price,
    fa.return_count,
    fa.total_return_amt,
    fa.net_sales_ratio,
    CASE 
        WHEN fa.net_sales_ratio < 0.5 THEN 'Poor Performance'
        WHEN fa.net_sales_ratio BETWEEN 0.5 AND 0.75 THEN 'Average Performance'
        ELSE 'Good Performance'
    END AS performance_category
FROM 
    FinalAnalysis fa
WHERE 
    fa.total_sales > 1000
ORDER BY 
    fa.net_sales_ratio DESC;
