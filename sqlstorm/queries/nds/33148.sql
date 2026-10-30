
WITH  CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_order_value,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cs.total_sales,
    cs.total_orders,
    cs.avg_order_value,
    cr.total_returns,
    cr.total_return_amount,
    cr.return_count
FROM 
    customer c
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    SalesSummary cs ON c.c_customer_sk = cs.ws_bill_customer_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
WHERE 
    (cd.cd_gender = 'F' AND cs.total_sales > 1000) 
    OR (cd.cd_gender = 'M' AND cr.return_count > 5)
ORDER BY 
    cs.total_sales DESC NULLS LAST
LIMIT 100;
