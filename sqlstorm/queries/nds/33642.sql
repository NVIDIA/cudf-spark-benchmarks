
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
), 
PopularItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(s.total_net_profit, 0) AS net_profit
    FROM item i
    LEFT JOIN SalesCTE s ON i.i_item_sk = s.ws_item_sk
    WHERE s.rank IS NOT NULL AND s.rank <= 5
), 
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt
    FROM web_returns
    GROUP BY wr_returning_customer_sk
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(COALESCE(cr.total_return_amt, 0)) AS total_customer_return
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    pi.i_item_id,
    pi.i_item_desc,
    pi.net_profit,
    ci.total_customer_return,
    CASE 
        WHEN ci.total_customer_return IS NULL THEN 'No Returns'
        WHEN ci.total_customer_return > 100 THEN 'Frequent Returner'
        ELSE 'Infrequent Returner' 
    END AS return_status
FROM CustomerInfo ci
JOIN PopularItems pi ON ci.total_customer_return > 0
ORDER BY ci.total_customer_return DESC, pi.net_profit DESC
LIMIT 10;
