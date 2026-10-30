
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales_amount,
        COUNT(DISTINCT ws_order_number) AS sales_count
    FROM 
        web_sales
    GROUP BY ws_bill_customer_sk
),
ReturnStatistics AS (
    SELECT 
        cr.returning_customer_sk,
        cr.returning_cdemo_sk,
        cr.returning_addr_sk,
        COALESCE(c.return_count, 0) AS returns_count,
        COALESCE(c.total_return_amount, 0) AS returns_total
    FROM 
        CustomerReturns c
    FULL OUTER JOIN
        (SELECT DISTINCT 
            sr_customer_sk AS returning_customer_sk,
            sr_cdemo_sk AS returning_cdemo_sk,
            sr_addr_sk AS returning_addr_sk
        FROM 
            store_returns) cr 
    ON c.sr_customer_sk = cr.returning_customer_sk
),
SalesAndReturns AS (
    SELECT 
        r.returning_customer_sk,
        r.returns_count,
        r.returns_total,
        COALESCE(s.total_sales_amount, 0) AS total_sales_amount,
        COALESCE(s.sales_count, 0) AS sales_count,
        (r.returns_total / NULLIF(s.total_sales_amount, 0)) * 100 AS return_percentage
    FROM 
        ReturnStatistics r
    LEFT JOIN 
        SalesData s 
    ON r.returning_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    r.returning_customer_sk,
    r.returns_count,
    r.returns_total,
    r.total_sales_amount,
    r.sales_count,
    CASE 
        WHEN r.total_sales_amount > 0 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value_category,
    RANK() OVER (ORDER BY return_percentage DESC) AS return_rank
FROM 
    SalesAndReturns r
WHERE 
    r.returning_customer_sk IS NOT NULL
    AND (r.returns_count > 0 OR r.total_sales_amount > 0)
ORDER BY 
    r.return_percentage DESC;
