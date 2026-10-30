
WITH RankedReturns AS (
    SELECT 
        COALESCE(sr_customer_sk, wr_returning_customer_sk) AS customer_sk,
        COALESCE(sr_return_quantity, wr_return_quantity) AS return_quantity,
        COALESCE(sr_return_amt, wr_return_amt) AS return_amt,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(sr_customer_sk, wr_returning_customer_sk) ORDER BY COALESCE(sr_return_amt, wr_return_amt) DESC) AS rn
    FROM store_returns sr
    FULL OUTER JOIN web_returns wr ON sr_item_sk = wr_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        AVG(ws.ws_ext_sales_price) AS avg_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
IncomeDistribution AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        SUM(c.total_spent) AS total_income
    FROM CustomerStats c
    JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    rs.return_quantity,
    CASE 
        WHEN rs.rn = 1 THEN 'Top Returner'
        WHEN rs.return_quantity > 10 THEN 'Frequent Returner'
        ELSE 'Casual Returner'
    END AS return_category,
    id.customer_count,
    id.total_income
FROM RankedReturns rs
JOIN CustomerStats cs ON rs.customer_sk = cs.c_customer_sk
JOIN IncomeDistribution id ON cs.total_spent BETWEEN id.customer_count AND id.total_income
WHERE rs.return_amt IS NOT NULL
    AND cs.order_count > 1
ORDER BY cs.total_spent DESC, rs.return_quantity DESC
LIMIT 100 OFFSET 10;
