
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk AS customer_id,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax,
        SUM(sr_net_loss) AS total_net_loss
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebSalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws_web_page_sk) AS pages_visited
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        cr.customer_id,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(cr.total_return_tax, 0) AS total_return_tax,
        COALESCE(cr.total_net_loss, 0) AS total_net_loss,
        COALESCE(ws.total_sales, 0) AS total_sales,
        COALESCE(ws.total_orders, 0) AS total_orders,
        ws.avg_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN WebSalesData ws ON cr.customer_id = ws.customer_id
    JOIN CustomerDemographics cd ON COALESCE(cr.customer_id, ws.customer_id) = cd.customer_id
)
SELECT 
    customer_id,
    total_returns,
    total_return_amt,
    total_return_tax,
    total_net_loss,
    total_sales,
    total_orders,
    avg_net_profit,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate,
    CASE 
        WHEN total_sales > 0 THEN ROUND((total_returns::numeric / total_orders) * 100, 2)
        ELSE 0 
    END AS return_rate_percentage
FROM 
    SalesSummary
WHERE 
    (total_returns > 10 OR total_sales > 1000)
    AND cd_gender IS NOT NULL
ORDER BY 
    return_rate_percentage DESC;
