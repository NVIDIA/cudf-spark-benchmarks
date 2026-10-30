
WITH RankedCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_quantity) DESC) AS rank_within_gender
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_marital_status IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
IncomeRanges AS (
    SELECT
        hd.hd_demo_sk,
        CASE
            WHEN ib.ib_lower_bound IS NULL OR ib.ib_upper_bound IS NULL THEN 'Unknown'
            ELSE CONCAT('$', ib.ib_lower_bound, ' - $', ib.ib_upper_bound)
        END AS income_range
    FROM household_demographics hd
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.total_quantity,
        ir.income_range
    FROM RankedCustomers rc
    JOIN IncomeRanges ir ON rc.c_customer_sk = ir.hd_demo_sk
    WHERE rc.rank_within_gender <= 5
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    COALESCE(tc.total_quantity, 0) AS total_quantity,
    tc.income_range,
    CASE 
        WHEN tc.cd_gender IS NULL THEN 'Gender Not Specified'
        ELSE 'Gender Specified'
    END AS gender_info,
    CASE 
        WHEN total_quantity > 100 THEN 'High Volume Customer'
        ELSE 'Standard Volume Customer'
    END AS customer_category
FROM TopCustomers tc
FULL OUTER JOIN customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
WHERE ca.ca_state IS NOT NULL OR tc.income_range = 'Unknown'
ORDER BY tc.total_quantity DESC NULLS LAST;
