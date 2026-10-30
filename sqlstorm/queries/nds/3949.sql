
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedSummary AS (
    SELECT 
        COALESCE(SR.sr_customer_sk, SS.ws_bill_customer_sk) AS customer_sk,
        COALESCE(SR.total_returns, 0) AS total_returns,
        COALESCE(SR.total_return_amount, 0) AS total_return_amount,
        COALESCE(SS.total_sales, 0) AS total_sales,
        COALESCE(SS.total_quantity_sold, 0) AS total_quantity_sold
    FROM 
        CustomerReturns SR
    FULL OUTER JOIN 
        SalesSummary SS 
    ON 
        SR.sr_customer_sk = SS.ws_bill_customer_sk
),
FinalMetrics AS (
    SELECT 
        customer_sk,
        total_returns,
        total_return_amount,
        total_sales,
        total_quantity_sold,
        CASE 
            WHEN total_sales > 0 THEN ROUND((total_return_amount / total_sales) * 100, 2)
            ELSE 0
        END AS return_rate_percentage,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CombinedSummary
)
SELECT 
    CM.customer_sk,
    CM.total_returns,
    CM.total_return_amount,
    CM.total_sales,
    CM.total_quantity_sold,
    CM.return_rate_percentage,
    CASE 
        WHEN CM.return_rate_percentage > 10 THEN 'High Return Rate'
        WHEN CM.return_rate_percentage BETWEEN 5 AND 10 THEN 'Moderate Return Rate'
        ELSE 'Low Return Rate'
    END AS return_rate_category
FROM 
    FinalMetrics CM
WHERE 
    CM.total_sales > 0
ORDER BY 
    CM.sales_rank;
