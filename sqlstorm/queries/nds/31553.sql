
WITH  TopCustomers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY total_profit DESC
    LIMIT 10
),
SalesData AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_tax) AS average_tax,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
AnnualTrends AS (
    SELECT 
        sd.d_year,
        sd.total_sales,
        sd.average_tax,
        sd.total_orders,
        sd.total_net_profit,
        LAG(sd.total_sales) OVER (ORDER BY sd.d_year) AS previous_year_sales,
        CASE 
            WHEN LAG(sd.total_sales) OVER (ORDER BY sd.d_year) IS NULL THEN NULL
            ELSE (sd.total_sales - LAG(sd.total_sales) OVER (ORDER BY sd.d_year)) / NULLIF(LAG(sd.total_sales) OVER (ORDER BY sd.d_year), 0) * 100 
        END AS sales_growth_rate
    FROM SalesData sd
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    at.d_year,
    at.total_sales,
    at.total_net_profit,
    COALESCE(at.sales_growth_rate, 0) AS sales_growth_rate
FROM TopCustomers tc
JOIN AnnualTrends at ON at.d_year IN (2021, 2022)
WHERE at.total_net_profit > 10000
ORDER BY at.d_year DESC, tc.total_profit DESC
LIMIT 50
