
WITH CustomerStats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS income_band_rank
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, hd.hd_income_band_sk
),
TopCustomers AS (
    SELECT
        c.*,
        ROW_NUMBER() OVER (PARTITION BY hd_income_band_sk ORDER BY total_net_profit DESC) AS profit_rank
    FROM
        CustomerStats c
    WHERE 
        order_count > 5
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_net_profit,
    CASE
        WHEN tc.hd_income_band_sk IS NULL THEN 'No Income Band'
        ELSE ib.ib_lower_bound || ' - ' || ib.ib_upper_bound
    END AS income_band,
    (SELECT COUNT(DISTINCT sr_ticket_number) FROM store_returns sr WHERE sr.sr_customer_sk = tc.c_customer_sk) AS return_count,
    (SELECT SUM(sr_return_amt) FROM store_returns sr WHERE sr.sr_customer_sk = tc.c_customer_sk) AS total_returns,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = tc.c_customer_sk) AS store_sales_count
FROM
    TopCustomers tc
LEFT JOIN income_band ib ON tc.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    tc.profit_rank <= 10
ORDER BY
    tc.total_net_profit DESC;
