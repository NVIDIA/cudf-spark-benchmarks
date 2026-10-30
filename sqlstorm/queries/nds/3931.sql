
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        AVG(ws.ws_ext_sales_price) AS avg_order_value
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
),
IncomeDetails AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
ReturnStats AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
FinalStats AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cd_gender,
        cd_marital_status,
        cs.order_count,
        COALESCE(id.ib_lower_bound, 0) AS income_lower_bound,
        COALESCE(id.ib_upper_bound, 0) AS income_upper_bound,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        COALESCE(rs.return_count, 0) AS return_count,
        cs.total_spent,
        cs.avg_order_value,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM CustomerStats cs
    LEFT JOIN IncomeDetails id ON cs.cd_purchase_estimate BETWEEN id.ib_lower_bound AND id.ib_upper_bound
    LEFT JOIN ReturnStats rs ON cs.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    fs.c_customer_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.cd_gender,
    fs.cd_marital_status,
    fs.order_count,
    fs.income_lower_bound,
    fs.income_upper_bound,
    fs.total_returns,
    fs.total_return_amount,
    fs.return_count,
    fs.total_spent,
    fs.avg_order_value
FROM FinalStats fs
WHERE fs.total_spent > (SELECT AVG(total_spent) FROM FinalStats)
AND fs.return_count > 0
ORDER BY fs.total_spent DESC
LIMIT 10;
