
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_order_number) AS total_web_returns,
        SUM(wr_return_amt_inc_tax) AS total_web_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
), 
ReturnStats AS (
    SELECT 
        cr.sr_customer_sk AS customer_sk,
        COALESCE(cr.total_returns, 0) AS store_return_count,
        COALESCE(wr.total_web_returns, 0) AS web_return_count,
        COALESCE(cr.total_return_amount, 0) AS store_return_total,
        COALESCE(wr.total_web_return_amount, 0) AS web_return_total,
        CASE 
            WHEN COALESCE(cr.total_returns, 0) = 0 THEN 'No Store Returns'
            WHEN COALESCE(wr.total_web_returns, 0) = 0 THEN 'No Web Returns'
            ELSE 'Both Types of Returns'
        END AS return_type
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        WebReturns wr ON cr.sr_customer_sk = wr.wr_returning_customer_sk
), 
RevenueDistribution AS (
    SELECT
        r.customer_sk,
        (r.store_return_count + r.web_return_count) * 1.0 / NULLIF((r.store_return_total + r.web_return_total), 0) AS return_rate
    FROM 
        ReturnStats r
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    rd.return_rate,
    CASE 
        WHEN rd.return_rate IS NULL THEN 'No Returns'
        WHEN rd.return_rate < 0.1 THEN 'Low Return Rate'
        WHEN rd.return_rate BETWEEN 0.1 AND 0.3 THEN 'Moderate Return Rate'
        ELSE 'High Return Rate'
    END AS return_rate_category
FROM 
    customer c
LEFT JOIN 
    RevenueDistribution rd ON c.c_customer_sk = rd.customer_sk
WHERE 
    c.c_birth_year > 1990
    AND (c.c_preferred_cust_flag IS NULL OR c.c_preferred_cust_flag = 'Y')
    AND c.c_last_review_date_sk IS NOT NULL
ORDER BY 
    return_rate DESC NULLS LAST
LIMIT 50;
