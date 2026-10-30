
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT r.sr_ticket_number) AS total_store_returns,
        SUM(r.sr_return_amt) AS total_store_return_amt,
        SUM(r.sr_return_tax) AS total_store_return_tax
    FROM 
        customer c
    LEFT JOIN 
        store_returns r ON c.c_customer_sk = r.sr_customer_sk
    GROUP BY 
        c.c_customer_id
), 
WebReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        SUM(wr.wr_return_tax) AS total_web_return_tax
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
),
CombinedReturns AS (
    SELECT 
        COALESCE(sr.c_customer_id, wr.c_customer_id) AS customer_id,
        COALESCE(sr.total_store_returns, 0) AS total_store_returns,
        COALESCE(sr.total_store_return_amt, 0) AS total_store_return_amt,
        COALESCE(sr.total_store_return_tax, 0) AS total_store_return_tax,
        COALESCE(wr.total_web_returns, 0) AS total_web_returns,
        COALESCE(wr.total_web_return_amt, 0) AS total_web_return_amt,
        COALESCE(wr.total_web_return_tax, 0) AS total_web_return_tax
    FROM 
        CustomerReturns sr
    FULL OUTER JOIN 
        WebReturns wr ON sr.c_customer_id = wr.c_customer_id
)
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name,
    COALESCE(cr.total_store_return_amt, 0) + COALESCE(cr.total_web_return_amt, 0) AS total_return_amount,
    DENSE_RANK() OVER (ORDER BY COALESCE(cr.total_store_return_amt, 0) + COALESCE(cr.total_web_return_amt, 0) DESC) AS return_rank
FROM 
    customer c
LEFT JOIN 
    CombinedReturns cr ON c.c_customer_id = cr.customer_id
WHERE 
    COALESCE(cr.total_store_return_amt, 0) + COALESCE(cr.total_web_return_amt, 0) > 0
ORDER BY 
    return_rank
LIMIT 10;
