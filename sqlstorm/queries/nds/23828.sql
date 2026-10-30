
WITH  CustomerSpending AS (
    SELECT c.c_customer_sk, SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
    HAVING SUM(ws.ws_net_paid) IS NOT NULL
),
EligibleCustomers AS (
    SELECT cs.c_customer_sk, cs.total_spent,
           cd.cd_gender, cd.cd_marital_status,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cs.total_spent DESC) AS rn
    FROM CustomerSpending cs
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
),
IncomeRanges AS (
    SELECT ib.ib_income_band_sk, COUNT(DISTINCT ec.c_customer_sk) AS num_customers
    FROM EligibleCustomers ec
    JOIN household_demographics hd ON ec.c_customer_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT ir.ib_income_band_sk,
       ir.num_customers,
       COALESCE(MAX(ec.total_spent), 0) AS max_spent,
       COALESCE(MIN(ec.total_spent), 0) AS min_spent
FROM IncomeRanges ir
LEFT JOIN EligibleCustomers ec ON ir.num_customers > 0 AND ec.total_spent IS NOT NULL
GROUP BY ir.ib_income_band_sk, ir.num_customers
HAVING COUNT(ec.c_customer_sk) > 5
ORDER BY ir.num_customers DESC, ir.ib_income_band_sk;
