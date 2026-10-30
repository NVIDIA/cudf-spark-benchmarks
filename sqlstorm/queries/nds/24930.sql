
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_profit,
        CASE 
            WHEN cs.total_orders = 0 THEN 'No Orders' 
            ELSE 'Active Customer' 
        END AS customer_status
    FROM 
        CustomerStats cs
    WHERE 
        cs.gender_rank <= 5
),
HighIncomeCustomers AS (
    SELECT 
        hd.hd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS high_income_count
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    WHERE 
        hd.hd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound >= 100000)
    GROUP BY 
        hd.hd_demo_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_profit,
    tc.customer_status,
    hic.high_income_count
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    HighIncomeCustomers hic ON tc.c_customer_sk = hic.hd_demo_sk
WHERE 
    (tc.total_orders IS NOT NULL OR hic.high_income_count IS NOT NULL)
    AND (hic.high_income_count IS NULL OR tc.total_profit > 5000)
ORDER BY 
    COALESCE(tc.total_profit, 0) DESC, 
    COALESCE(hic.high_income_count, 0) DESC;
