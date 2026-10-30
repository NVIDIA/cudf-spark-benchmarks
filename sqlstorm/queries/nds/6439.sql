
WITH CustomerSpend AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
    GROUP BY c.c_customer_sk
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        cs.total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM CustomerSpend cs
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE cs.total_spent > 1000
),
MonthlySales AS (
    SELECT 
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_monthly_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_month_seq
),
GenderSales AS (
    SELECT 
        hs.cd_gender,
        SUM(ms.total_monthly_sales) AS total_sales_by_gender
    FROM HighSpenders hs
    JOIN MonthlySales ms ON hs.c_customer_sk = hs.c_customer_sk
    GROUP BY hs.cd_gender
)
SELECT 
    gs.cd_gender,
    gs.total_sales_by_gender,
    COUNT(hs.c_customer_sk) AS number_of_high_spenders
FROM GenderSales gs
JOIN HighSpenders hs ON gs.cd_gender = hs.cd_gender
GROUP BY gs.cd_gender, gs.total_sales_by_gender
ORDER BY gs.total_sales_by_gender DESC;
