
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
RankedSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
),
IncomeDemographics AS (
    SELECT 
        h.hd_demo_sk,
        h.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        h.hd_buy_potential
    FROM household_demographics h
    JOIN income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    rs.c_first_name,
    rs.c_last_name,
    rs.total_sales,
    rd.ib_lower_bound,
    rd.ib_upper_bound,
    rd.hd_buy_potential
FROM RankedSales rs
JOIN IncomeDemographics rd ON rs.c_customer_sk = rd.hd_demo_sk
WHERE rs.sales_rank <= 10
ORDER BY total_sales DESC;
