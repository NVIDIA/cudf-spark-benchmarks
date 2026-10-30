
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > (SELECT AVG(sr_return_quantity) FROM store_returns)
        OR sr_returned_date_sk IS NOT NULL
),
MaxReturned AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        RankedReturns
    WHERE 
        rn = 1
    GROUP BY 
        sr_item_sk
),
StoreSalesCTE AS (
    SELECT 
        ss_store_sk,
        COUNT(DISTINCT ss_ticket_number) AS total_tickets,
        SUM(ss_net_paid) AS total_sales,
        SUM(ss_quantity) AS total_quantity
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = (SELECT MAX(d_year) FROM date_dim))
    GROUP BY 
        ss_store_sk
),
ReturnSales AS (
    SELECT 
        ss.ss_store_sk,
        ss.total_tickets,
        ss.total_sales,
        ss.total_quantity,
        COALESCE(mr.total_returned, 0) AS total_returned
    FROM 
        StoreSalesCTE ss
    LEFT JOIN 
        MaxReturned mr ON ss.ss_store_sk = mr.sr_item_sk
),
FinalResults AS (
    SELECT 
        rs.ss_store_sk,
        rs.total_tickets,
        rs.total_sales,
        rs.total_quantity,
        rs.total_returned,
        CASE 
            WHEN rs.total_returned > 0 AND rs.total_quantity > 0 THEN 
                ROUND((CAST(rs.total_returned AS decimal) / NULLIF(rs.total_quantity, 0)) * 100, 2)
            ELSE 0
        END AS return_rate
    FROM 
        ReturnSales rs
)
SELECT 
    d.d_date AS report_date,
    f.ss_store_sk,
    f.total_tickets,
    f.total_sales,
    f.total_quantity,
    f.total_returned,
    f.return_rate,
    CASE 
        WHEN f.return_rate > 50 THEN 'High'
        WHEN f.return_rate BETWEEN 20 AND 50 THEN 'Moderate'
        ELSE 'Low'
    END AS return_rate_category
FROM 
    FinalResults f
CROSS JOIN 
    (SELECT DISTINCT d_date FROM date_dim WHERE d_current_year = 'Y') d
WHERE 
    d.d_date IS NOT NULL
ORDER BY 
    f.return_rate DESC, f.total_sales DESC;
