
WITH  SalesCTE AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        ss_sales_price,
        ss_quantity,
        ss_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY ss_ext_sales_price DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
),
AvgSales AS (
    SELECT 
        ss_store_sk,
        AVG(ss_ext_sales_price) AS avg_sales_price
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
ReturnDetails AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
)

SELECT 
    s.ss_store_sk,
    s.ss_sales_price AS sales_price,
    a.avg_sales_price,
    r.total_return_amt,
    r.total_return_quantity,
    CASE 
        WHEN r.total_return_amt IS NOT NULL THEN 'Return Data Available' 
        ELSE 'No Return Data' 
    END AS return_data_status
FROM 
    SalesCTE s
JOIN 
    AvgSales a ON s.ss_store_sk = a.ss_store_sk
LEFT JOIN 
    ReturnDetails r ON s.ss_store_sk = r.sr_store_sk
WHERE 
    s.sales_rank <= 10
ORDER BY 
    s.ss_store_sk, s.ss_sales_price DESC;
