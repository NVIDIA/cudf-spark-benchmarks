
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesPerCustomer AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
),
ReturnRates AS (
    SELECT 
        SP.ws_bill_customer_sk,
        COALESCE(cr.total_returns, 0) AS total_returns,
        SP.total_sales,
        CASE 
            WHEN SP.total_sales > 0 THEN COALESCE(cr.total_returns, 0) * 1.0 / SP.total_sales
            ELSE 0
        END AS return_rate
    FROM 
        SalesPerCustomer SP
    LEFT JOIN 
        CustomerReturns cr ON SP.ws_bill_customer_sk = cr.sr_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    RR.ws_bill_customer_sk,
    RR.total_returns,
    RR.total_sales,
    RR.return_rate,
    CASE 
        WHEN RR.return_rate > 0.1 THEN 'High Return Rate'
        ELSE 'Normal Return Rate'
    END AS return_category
FROM 
    ReturnRates RR
JOIN 
    customer c ON RR.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    RR.return_rate IS NOT NULL
ORDER BY 
    RR.return_rate DESC
LIMIT 100;
