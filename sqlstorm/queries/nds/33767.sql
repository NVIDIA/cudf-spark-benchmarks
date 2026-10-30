
WITH  SalesCTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_net_paid) > 1000
),
CustomerReturns AS (
    SELECT
        wr_returning_customer_sk,
        COUNT(*) AS return_count,
        SUM(wr_return_amt) AS total_return_amt
    FROM web_returns
    WHERE wr_return_quantity > 0
    GROUP BY wr_returning_customer_sk
),
AggregateCustomerData AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(cr.total_return_amt, 0) DESC) AS return_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL 
      AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
),
BestSellingItems AS (
    SELECT
        i_item_sk,
        i_product_name,
        ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS ranking
    FROM SalesCTE
    JOIN item ON SalesCTE.ws_item_sk = item.i_item_sk
)
SELECT
    a.c_first_name,
    a.c_last_name,
    a.total_return_amt,
    b.i_product_name,
    b.ranking
FROM AggregateCustomerData a
JOIN BestSellingItems b ON a.c_customer_sk = b.i_item_sk
WHERE a.return_rank <= 5
ORDER BY a.total_return_amt DESC, b.ranking
LIMIT 10;
