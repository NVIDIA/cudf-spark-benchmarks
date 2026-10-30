
WITH CustomerSales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.total_sales
    FROM CustomerSales cs
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE cs.total_sales > 1000 AND cd.cd_gender = 'F'
),
DateSummary AS (
    SELECT d.d_year, SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
TopYears AS (
    SELECT d_year, total_revenue, RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM DateSummary
)
SELECT hs.c_first_name, hs.c_last_name, ty.d_year, ty.total_revenue
FROM HighSpenders hs
JOIN TopYears ty ON hs.total_sales > (SELECT AVG(total_revenue) FROM TopYears)
ORDER BY ty.total_revenue DESC, hs.c_last_name, hs.c_first_name;
