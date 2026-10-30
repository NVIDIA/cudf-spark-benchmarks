
WITH CustomerPurchaseSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),

ReturnsSummary AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),

FinalReport AS (
    SELECT 
        ps.c_first_name,
        ps.c_last_name,
        ps.total_quantity,
        ps.total_spent,
        rs.total_returns,
        rs.total_return_amount,
        CASE 
            WHEN ps.total_spent > 1000 THEN 'High Value'
            WHEN ps.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment,
        ps.gender_rank
    FROM CustomerPurchaseSummary ps
    LEFT JOIN ReturnsSummary rs ON ps.c_customer_sk = rs.sr_customer_sk
)

SELECT 
    fr.c_first_name,
    fr.c_last_name,
    fr.total_quantity,
    fr.total_spent,
    COALESCE(fr.total_returns, 0) AS total_returns,
    COALESCE(fr.total_return_amount, 0) AS total_return_amount,
    fr.customer_value_segment,
    CASE 
        WHEN fr.total_spent IS NULL THEN 'No Purchases'
        WHEN fr.total_spent > 1000 THEN 'VIP Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM FinalReport fr
WHERE fr.gender_rank <= 10
ORDER BY fr.total_spent DESC;
