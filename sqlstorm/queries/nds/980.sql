
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_returned_amt,
        SUM(sr_return_quantity) AS total_returned_qty
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_order_number) AS web_total_returns,
        SUM(wr_return_amt) AS web_total_returned_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
SalesTotals AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
IncomeEstimates AS (
    SELECT 
        cd_demo_sk,
        CASE
            WHEN cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS income_category
    FROM 
        customer_demographics
),
CustomerStatistics AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(wr.web_total_returns, 0) AS web_total_returns,
        COALESCE(st.total_net_paid, 0) AS total_net_paid,
        COALESCE(st.total_orders, 0) AS total_orders,
        ie.income_category
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        WebReturns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN 
        SalesTotals st ON c.c_customer_sk = st.customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        IncomeEstimates ie ON cd.cd_demo_sk = ie.cd_demo_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_returns,
    cs.web_total_returns,
    cs.total_net_paid,
    cs.income_category,
    CASE 
        WHEN cs.total_returns > 5 THEN 'Frequent Returner'
        WHEN cs.total_orders > 10 THEN 'Active Customer'
        ELSE 'Occasional Customer'
    END AS customer_status
FROM 
    CustomerStatistics cs
WHERE 
    cs.total_net_paid > 1000
ORDER BY 
    cs.total_returns DESC, cs.total_net_paid DESC
LIMIT 50;
