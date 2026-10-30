WITH CustomerSpend AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
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
    WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSpend)
),
MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_paid) AS monthly_sales
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
TopMonths AS (
    SELECT 
        d_year, 
        d_month_seq, 
        monthly_sales,
        RANK() OVER (ORDER BY monthly_sales DESC) AS sales_rank
    FROM MonthlySales
)
SELECT 
    hs.c_customer_sk,
    hs.total_spent,
    hs.total_orders,
    hs.cd_gender,
    hs.cd_marital_status,
    hs.cd_education_status,
    tm.d_year,
    tm.d_month_seq,
    tm.monthly_sales
FROM HighSpenders hs
JOIN TopMonths tm ON hs.total_orders > 5 
WHERE tm.sales_rank <= 10 
ORDER BY hs.total_spent DESC, tm.monthly_sales DESC;