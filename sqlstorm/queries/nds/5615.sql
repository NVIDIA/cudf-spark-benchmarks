
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1975 AND 2000
    GROUP BY c.c_customer_sk
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        cs.total_orders,
        cs.total_net_profit,
        cs.avg_sales_price
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_net_profit > 10000
),
MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS monthly_net_profit
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
SalesGrowth AS (
    SELECT
        ms1.d_year,
        ms1.d_month_seq,
        CASE 
            WHEN ms1.monthly_net_profit = 0 THEN 0
            ELSE (ms1.monthly_net_profit - ms2.monthly_net_profit) / NULLIF(ms2.monthly_net_profit, 0) * 100 
        END AS growth_percentage
    FROM MonthlySales ms1
    LEFT JOIN MonthlySales ms2 ON ms1.d_year = ms2.d_year AND ms1.d_month_seq = ms2.d_month_seq + 1
)
SELECT 
    tc.c_customer_sk,
    tc.total_orders,
    tc.total_net_profit,
    tc.avg_sales_price,
    sg.d_year,
    sg.d_month_seq,
    sg.growth_percentage
FROM TopCustomers tc
JOIN SalesGrowth sg ON sg.d_year = EXTRACT(YEAR FROM DATE '2002-10-01') AND sg.d_month_seq = EXTRACT(MONTH FROM DATE '2002-10-01');
