WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_qty,
        SUM(sr_return_amt) AS total_returned_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS rank
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_quantity) AS avg_quantity
    FROM web_sales
    GROUP BY ws_ship_customer_sk
),
CombinedData AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        ci.ca_state,
        COALESCE(rr.total_returned_qty, 0) AS total_returned_qty,
        COALESCE(rr.total_returned_amt, 0) AS total_returned_amt,
        COALESCE(sd.total_net_profit, 0) AS total_net_profit,
        sd.order_count,
        ci.purchase_rank
    FROM CustomerInfo ci
    LEFT JOIN RankedReturns rr ON ci.c_customer_sk = rr.sr_customer_sk AND rr.rank = 1
    LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ws_ship_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_net_profit > 0 THEN 'Profitable'
        WHEN total_returned_qty > 0 THEN 'Returned Items'
        ELSE 'No Activity'
    END AS activity_status
FROM CombinedData
WHERE purchase_rank <= 50
ORDER BY total_net_profit DESC, total_returned_amt DESC
LIMIT 100;