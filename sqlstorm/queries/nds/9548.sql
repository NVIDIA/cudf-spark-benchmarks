
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, hd.hd_income_band_sk
),
TopCustomers AS (
    SELECT 
        cs.*,
        RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_profit DESC) AS customer_rank
    FROM 
        CustomerSummary cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_purchase_estimate,
    tc.total_profit,
    tc.total_orders,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    TopCustomers tc
JOIN 
    income_band ib ON tc.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    tc.customer_rank <= 5
ORDER BY 
    ib.ib_lower_bound, total_profit DESC;
