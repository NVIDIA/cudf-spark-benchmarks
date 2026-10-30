
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(DISTINCT cr_order_number) AS return_count,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
TopCustomers AS (
    SELECT 
        cr.cr_returning_customer_sk AS returning_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        CustomerReturns cr
    JOIN 
        customer_demographics cd ON cr.cr_returning_customer_sk = cd.cd_demo_sk
    WHERE 
        cr.return_count > 5
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        tc.returning_customer_sk,
        tc.cd_gender,
        tc.cd_marital_status,
        tc.cd_education_status,
        tc.cd_purchase_estimate,
        ss.total_sales,
        ss.avg_net_profit,
        ss.order_count
    FROM 
        TopCustomers tc
    LEFT JOIN 
        SalesSummary ss ON tc.returning_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    fr.returning_customer_sk,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.cd_education_status,
    fr.cd_purchase_estimate,
    COALESCE(fr.total_sales, 0) AS total_sales,
    COALESCE(fr.avg_net_profit, 0) AS avg_net_profit,
    COALESCE(fr.order_count, 0) AS order_count
FROM 
    FinalReport fr
ORDER BY 
    fr.total_sales DESC
LIMIT 10;
