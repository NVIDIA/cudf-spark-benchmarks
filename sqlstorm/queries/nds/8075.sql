
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS num_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ib.ib_income_band_sk
),
TopCustomers AS (
    SELECT
        c.c_customer_id AS customer_id,
        c.total_web_sales,
        c.num_orders,
        RANK() OVER (ORDER BY c.total_web_sales DESC) AS sales_rank
    FROM CustomerSales c
)
SELECT
    tc.customer_id,
    tc.total_web_sales,
    tc.num_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_income_band_sk,
    COUNT(sr.sr_ticket_number) AS returns_count,
    SUM(sr.sr_return_amt) AS total_return_amount
FROM TopCustomers tc
LEFT JOIN customer c ON tc.customer_id = c.c_customer_id
LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE tc.sales_rank <= 100
GROUP BY
    tc.customer_id,
    tc.total_web_sales,
    tc.num_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_income_band_sk
ORDER BY 
    tc.total_web_sales DESC;
