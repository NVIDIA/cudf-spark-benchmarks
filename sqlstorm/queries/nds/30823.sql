
WITH RecursiveSales AS (
    SELECT 
        ws_order_number, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_item_sk) AS item_count,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_order_number
),
TopSales AS (
    SELECT 
        ws_order_number, 
        total_sales, 
        item_count
    FROM 
        RecursiveSales
    WHERE sales_rank <= 5
),
AverageSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales
    FROM 
        TopSales
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk, 
        COUNT(DISTINCT wr_order_number) AS return_count,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cs.return_count, 0) AS total_returns,
    COALESCE(cs.total_return_amount, 0) AS return_amount,
    ts.total_sales,
    CASE 
        WHEN ts.total_sales > av.avg_sales THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_category
FROM 
    customer c
LEFT JOIN 
    CustomerReturns cs ON c.c_customer_sk = cs.wr_returning_customer_sk
LEFT JOIN 
    TopSales ts ON c.c_customer_sk = ts.ws_order_number  
CROSS JOIN 
    AverageSales av
WHERE 
    c.c_birth_country IS NOT NULL
ORDER BY 
    total_returns DESC, 
    return_amount DESC
LIMIT 100;
