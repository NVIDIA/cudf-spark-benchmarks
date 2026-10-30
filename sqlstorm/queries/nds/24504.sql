
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit > 0
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS return_count,
        SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
HighSpendingCustomers AS (
    SELECT
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) > 5000
),
MixedReturns AS (
    SELECT 
        cd.cd_demo_sk AS returning_cdemo_sk,
        COALESCE(r.return_count, 0) AS web_return_count,
        COALESCE(hs.total_spent, 0) AS web_total_spent
    FROM 
        customer_demographics cd
    LEFT JOIN 
        CustomerReturns r ON cd.cd_demo_sk = r.wr_returning_customer_sk
    LEFT JOIN 
        HighSpendingCustomers hs ON cd.cd_demo_sk = hs.c_customer_sk
)
SELECT 
    r.returning_cdemo_sk,
    r.web_return_count,
    r.web_total_spent,
    CASE 
        WHEN r.web_return_count = 0 THEN 'No Returns'
        WHEN r.web_return_count > 5 THEN 'Frequent Returner'
        ELSE 'Occasional Returner'
    END AS return_category,
    CASE 
        WHEN r.web_total_spent = 0 THEN 'No Spending'
        WHEN r.web_total_spent > 10000 THEN 'High Roller'
        WHEN r.web_total_spent BETWEEN 5000 AND 10000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM 
    MixedReturns r
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM RankedSales rs 
        WHERE rs.ws_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_ext_sales_price < 50)
        AND rs.price_rank = 1
    )
ORDER BY r.web_total_spent DESC NULLS LAST;
