
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk) AS total_quantity,
        AVG(ws_sales_price) OVER (PARTITION BY ws_item_sk) AS avg_sales_price
    FROM 
        web_sales
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        COUNT(*) AS return_count,
        SUM(wr_return_amt) AS total_return_amount,
        AVG(wr_return_quantity) AS avg_return_quantity
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
FilteredSales AS (
    SELECT 
        r.ws_sold_date_sk,
        r.ws_item_sk,
        r.sales_rank,
        r.total_quantity,
        r.avg_sales_price,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN r.sales_rank = 1 THEN 'Top Seller'
            ELSE 'Regular Seller'
        END AS seller_category
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerReturns cr ON r.ws_item_sk = cr.wr_item_sk
)
SELECT 
    fn1.seller_category,
    COUNT(*) AS item_count,
    SUM(fn1.total_quantity) AS total_sold,
    SUM(fn1.total_return_amount) AS total_returns,
    AVG(fn1.avg_sales_price) AS average_price,
    SUM(CASE 
        WHEN fn1.return_count > 0 THEN fn1.return_count * -1 
        ELSE fn1.total_quantity 
    END) AS total_net_sales
FROM 
    FilteredSales fn1
GROUP BY 
    fn1.seller_category
HAVING 
    SUM(fn1.total_quantity) > 10
    AND AVG(fn1.avg_sales_price) IS NOT NULL
ORDER BY 
    total_net_sales DESC
LIMIT 10;
