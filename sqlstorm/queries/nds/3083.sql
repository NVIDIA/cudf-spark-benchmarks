
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS income_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_orders,
        cs.total_profit
    FROM 
        CustomerStats cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.income_rank <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_orders, 0) AS total_orders,
    ROUND(tc.total_profit, 2) AS total_profit,
    (SELECT SUM(sr_return_amt) FROM store_returns sr WHERE sr.sr_customer_sk = tc.c_customer_sk) AS total_returns,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returning_customer_sk = tc.c_customer_sk) AS web_returns_count,
    (SELECT COUNT(*) FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = tc.c_customer_sk) AS catalog_sales_count
FROM 
    TopCustomers tc
ORDER BY 
    total_profit DESC;
