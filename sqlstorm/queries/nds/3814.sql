
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 10
),
IncomeRanges AS (
    SELECT 
        ib.ib_income_band_sk,
        (ib.ib_lower_bound + ib.ib_upper_bound) AS avg_income
    FROM 
        income_band ib
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    COALESCE(ir.avg_income, 0) AS average_income,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid_inc_tax) AS total_spent
FROM 
    TopCustomers tc
LEFT JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    household_demographics hd ON tc.c_customer_sk = hd.hd_demo_sk
LEFT JOIN 
    IncomeRanges ir ON hd.hd_income_band_sk = ir.ib_income_band_sk
WHERE 
    tc.cd_purchase_estimate > 1000
GROUP BY 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.cd_gender, 
    ir.avg_income
HAVING 
    SUM(ws.ws_net_paid_inc_tax) > 10000
ORDER BY 
    total_spent DESC;
