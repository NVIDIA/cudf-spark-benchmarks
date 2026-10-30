
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_net_profit,
        rs.total_orders
    FROM item i
    JOIN RecursiveSales rs ON i.i_item_sk = rs.ws_item_sk
    WHERE rs.item_rank <= 10
),
CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_returns_amt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_estimate,
        MAX(cd.cd_credit_rating) AS top_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
FinalReport AS (
    SELECT 
        ti.i_item_id,
        ti.i_item_desc,
        ti.total_net_profit,
        ti.total_orders,
        cr.return_count,
        cr.total_returns_amt,
        cd.customer_count,
        cd.avg_estimate,
        cd.top_rating
    FROM TopItems ti
    LEFT JOIN CustomerReturns cr ON ti.total_orders = cr.return_count
    LEFT JOIN CustomerDemographics cd ON cd.customer_count > 100
)

SELECT 
    fr.i_item_id,
    fr.i_item_desc,
    fr.total_net_profit,
    fr.total_orders,
    COALESCE(fr.return_count, 0) AS return_count,
    COALESCE(fr.total_returns_amt, 0) AS total_returns_amt,
    COALESCE(fr.customer_count, 0) AS customer_count,
    COALESCE(fr.avg_estimate, 0) AS avg_estimate,
    fr.top_rating
FROM FinalReport fr
ORDER BY fr.total_net_profit DESC
LIMIT 50;
