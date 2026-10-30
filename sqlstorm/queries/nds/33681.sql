
WITH  CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
    UNION ALL
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_value
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
CustomerReturnSummary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(cr.total_returns), 0) AS total_returns,
        COALESCE(SUM(cr.total_return_value), 0) AS total_return_value
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesSummary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalSummary AS (
    SELECT 
        cus.c_customer_sk,
        cus.c_first_name,
        cus.c_last_name,
        COALESCE(sales.total_sales, 0) AS total_sales,
        cus.total_returns,
        cus.total_return_value,
        (COALESCE(sales.total_sales, 0) - cus.total_return_value) AS net_total
    FROM 
        CustomerReturnSummary cus
    LEFT JOIN 
        SalesSummary sales ON cus.c_customer_sk = sales.ws_bill_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_sales,
    f.total_returns,
    f.total_return_value,
    f.net_total,
    CASE 
        WHEN f.net_total < 0 THEN 'Negative'
        WHEN f.net_total = 0 THEN 'Break Even'
        ELSE 'Profitable'
    END AS profitability_status
FROM 
    FinalSummary f
WHERE 
    f.total_sales > 1000
ORDER BY 
    f.net_total DESC
LIMIT 50;
