
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS rn
    FROM store_returns
    GROUP BY sr_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        COALESCE(cd_credit_rating, 'Unknown') AS credit_status,
        CASE 
            WHEN cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM customer_demographics
),
TopReturnItems AS (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (ORDER BY r.total_returns DESC) AS rnk
    FROM RankedReturns r
    WHERE r.total_returns >= 5
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        COALESCE(pp.total_returns, 0) AS total_returns,
        COALESCE(pp.total_return_amt, 0) AS total_return_amt
    FROM item i
    LEFT JOIN TopReturnItems pp ON i.i_item_sk = pp.sr_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.value_category,
        cd.credit_status,
        COUNT(DISTINCT sr.sr_item_sk) AS num_items_returned
    FROM customer c
    LEFT JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.value_category, cd.credit_status
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.value_category,
    ci.credit_status,
    ss.total_profit,
    ss.num_orders,
    ss.avg_net_paid,
    SUM(id.total_returns) AS total_returns,
    SUM(id.total_return_amt) AS total_return_amt
FROM CustomerInfo ci
LEFT JOIN SalesSummary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN ItemDetails id ON ci.num_items_returned = id.total_returns
WHERE ci.value_category = 'High Value' 
  AND (ss.total_profit IS NULL OR ss.total_profit > 1000)
GROUP BY ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.value_category, ci.credit_status, ss.total_profit, ss.num_orders, ss.avg_net_paid
HAVING COUNT(*) > 1 OR AVG(ss.avg_net_paid) IS NOT NULL
ORDER BY ss.total_profit DESC, ci.c_last_name ASC NULLS LAST;
