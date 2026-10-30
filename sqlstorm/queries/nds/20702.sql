
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_customer_sk,
        sr_reason_sk,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM store_returns
    WHERE sr_return_quantity > 0
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN'
            ELSE CASE
                WHEN cd.cd_purchase_estimate < 100 THEN 'Low'
                WHEN cd.cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium'
                ELSE 'High'
            END
        END AS purchase_estimation_band
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
MaxReturnQty AS (
    SELECT 
        sr_item_sk,
        MAX(sr_return_quantity) AS max_return_qty
    FROM RankedReturns
    GROUP BY sr_item_sk
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY ws_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.purchase_estimation_band,
    COALESCE(rr.sr_return_quantity, 0) AS return_quantity,
    COALESCE(s.total_sold, 0) AS total_sold,
    COALESCE(s.total_profit, 0) AS total_profit
FROM CustomerInfo ci
LEFT JOIN RankedReturns rr ON ci.c_customer_sk = rr.sr_customer_sk AND rr.rn = 1
LEFT JOIN SalesSummary s ON rr.sr_item_sk = s.ws_item_sk
WHERE 
    (ci.cd_gender = 'M' OR ci.cd_marital_status = 'M') 
    AND (ci.purchase_estimation_band = 'High' OR rr.sr_return_quantity IS NOT NULL)
ORDER BY 
    ci.purchase_estimation_band DESC, 
    total_profit DESC, 
    return_quantity DESC
LIMIT 50;
