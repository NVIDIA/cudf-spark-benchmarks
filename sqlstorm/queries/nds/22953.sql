
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(cr_order_number) AS return_count,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_tax) AS total_return_tax
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
WebSalesAggregated AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.cd_purchase_estimate > (
        SELECT AVG(cd_purchase_estimate) 
        FROM customer_demographics 
        WHERE cd_gender = 'F'
    )
),
ReturningCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(wsa.total_net_paid, 0) AS total_net_paid,
        COALESCE(wsa.order_count, 0) AS order_count
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN WebSalesAggregated wsa ON c.c_customer_sk = wsa.ws_bill_customer_sk
),
FinalResults AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.return_count,
        rc.total_net_paid,
        rc.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.ca_state,
        CASE 
            WHEN rc.order_count = 0 THEN NULL 
            ELSE rc.total_net_paid / NULLIF(rc.order_count, 0)
        END AS avg_spent_per_order
    FROM ReturningCustomers rc
    JOIN CustomerDemographics cd ON rc.c_customer_sk = cd.c_customer_sk
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.return_count,
    fr.total_net_paid,
    fr.order_count,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.ca_state,
    fr.avg_spent_per_order,
    CASE 
        WHEN fr.return_count > 5 THEN 'Frequent Returner' 
        WHEN fr.return_count IS NULL THEN 'No Returns'
        ELSE 'Occasional Returner' 
    END AS return_category
FROM FinalResults fr
WHERE (fr.return_count >= (SELECT AVG(return_count) FROM FinalResults) OR fr.total_net_paid > 1000)
AND fr.cd_gender IS NOT NULL
ORDER BY fr.total_net_paid DESC
LIMIT 100;
