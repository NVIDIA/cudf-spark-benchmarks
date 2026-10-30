
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk, sr_customer_sk
),
CustomerSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sold_amount
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk, ws_bill_customer_sk
),
MonthlyReturns AS (
    SELECT 
        dd.d_month_seq,
        SUM(cr.total_returned_quantity) AS monthly_returned_quantity,
        SUM(cr.total_returned_amount) AS monthly_returned_amount
    FROM 
        CustomerReturns cr
    JOIN 
        date_dim dd ON cr.sr_returned_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_month_seq
),
MonthlySales AS (
    SELECT 
        dd.d_month_seq,
        SUM(cs.total_sold_quantity) AS monthly_sold_quantity,
        SUM(cs.total_sold_amount) AS monthly_sold_amount
    FROM 
        CustomerSales cs
    JOIN 
        date_dim dd ON cs.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_month_seq
),
ReturnVsSales AS (
    SELECT 
        COALESCE(mr.d_month_seq, ms.d_month_seq) AS d_month_seq,
        COALESCE(mr.monthly_returned_quantity, 0) AS returned_quantity,
        COALESCE(ms.monthly_sold_quantity, 0) AS sold_quantity,
        CASE 
            WHEN COALESCE(ms.monthly_sold_quantity, 0) = 0 THEN NULL 
            ELSE COALESCE(mr.monthly_returned_quantity, 0) * 100.0 / ms.monthly_sold_quantity 
        END AS return_rate_percentage
    FROM 
        MonthlyReturns mr
    FULL OUTER JOIN 
        MonthlySales ms ON mr.d_month_seq = ms.d_month_seq
)
SELECT 
    rvs.d_month_seq,
    rvs.returned_quantity,
    rvs.sold_quantity,
    rvs.return_rate_percentage,
    ROW_NUMBER() OVER (ORDER BY rvs.return_rate_percentage DESC) AS rank
FROM 
    ReturnVsSales rvs
WHERE 
    rvs.return_rate_percentage IS NOT NULL 
    AND rvs.return_rate_percentage > 0
ORDER BY 
    rvs.return_rate_percentage DESC;
