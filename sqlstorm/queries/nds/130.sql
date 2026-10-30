
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_net_loss) AS total_net_loss
    FROM store_returns
    GROUP BY sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_net_loss, 0) AS total_net_loss
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE cd.cd_purchase_estimate > 1000
),
TopItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_quantity) > 100
),
ItemPerformance AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(tt.total_sold_quantity, 0) AS total_sold_quantity,
        COALESCE(tt.total_net_profit, 0) AS total_net_profit,
        ROW_NUMBER() OVER (ORDER BY COALESCE(tt.total_net_profit, 0) DESC) AS item_rank
    FROM item i
    LEFT JOIN TopItems tt ON i.i_item_sk = tt.ws_item_sk
)
SELECT 
    hv.c_customer_sk,
    hv.c_first_name,
    hv.c_last_name,
    hv.cd_marital_status,
    hv.cd_purchase_estimate,
    hv.cd_credit_rating,
    ip.i_item_sk,
    ip.i_item_desc,
    ip.total_sold_quantity,
    ip.total_net_profit
FROM HighValueCustomers hv
JOIN ItemPerformance ip ON hv.total_net_loss < ip.total_net_profit
WHERE ip.item_rank <= 10
ORDER BY hv.c_customer_sk, ip.total_net_profit DESC;
