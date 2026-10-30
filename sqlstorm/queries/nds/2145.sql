
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebsiteReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity_web,
        SUM(wr_return_amt) AS total_return_amt_web
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
TotalReturns AS (
    SELECT 
        COALESCE(c.c_customer_id, 'Unknown') AS customer_id,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(wr.total_returned_quantity_web, 0) AS total_web_returned_quantity,
        COALESCE(wr.total_return_amt_web, 0) AS total_web_return_amt
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        WebsiteReturns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
),
RankedReturns AS (
    SELECT 
        customer_id,
        total_returned_quantity + total_web_returned_quantity AS combined_returns,
        ROW_NUMBER() OVER (ORDER BY (total_returned_quantity + total_web_returned_quantity) DESC) AS return_rank
    FROM 
        TotalReturns
)
SELECT 
    customer_id,
    combined_returns,
    return_rank,
    CASE 
        WHEN combined_returns > 100 THEN 'High Return'
        WHEN combined_returns BETWEEN 50 AND 100 THEN 'Medium Return'
        ELSE 'Low Return' 
    END AS return_category
FROM 
    RankedReturns
WHERE 
    return_rank <= 100
ORDER BY 
    combined_returns DESC;
