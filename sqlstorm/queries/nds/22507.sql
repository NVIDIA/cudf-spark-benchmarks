
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_quantity DESC) AS rank_quantity
    FROM web_sales ws
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month IS NOT NULL
        AND c.c_birth_year BETWEEN 1970 AND 1990
),
AggregateReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt) AS total_returned_amt
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
CustomerSummary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COALESCE(SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END), 0) AS married_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
    GROUP BY cd.cd_gender
)
SELECT 
    COALESCE(cs.cd_gender, 'Unknown') AS customer_gender,
    rs.rank_profit,
    rs.rank_quantity,
    rs.ws_item_sk,
    COALESCE(ar.total_returned, 0) AS total_returned,
    COALESCE(ar.total_returned_amt, 0) AS total_returned_amt,
    cs.customer_count,
    cs.avg_purchase_estimate,
    cs.married_count
FROM RankedSales rs
LEFT JOIN AggregateReturns ar ON rs.ws_item_sk = ar.wr_item_sk
JOIN CustomerSummary cs ON rs.rank_profit = cs.customer_count
WHERE rs.rank_profit <= 10 
  AND (ar.total_returned IS NULL OR ar.total_returned < 5)
GROUP BY 
    cs.cd_gender,
    rs.rank_profit,
    rs.rank_quantity,
    rs.ws_item_sk,
    ar.total_returned,
    ar.total_returned_amt,
    cs.customer_count,
    cs.avg_purchase_estimate,
    cs.married_count
ORDER BY customer_gender, total_returned_amt DESC;
