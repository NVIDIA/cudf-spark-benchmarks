
WITH CustomerSales AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_spent DESC) AS rank_in_band
    FROM CustomerSales
)
SELECT 
    rs.c_first_name,
    rs.c_last_name,
    rs.total_spent,
    rs.cd_gender,
    ib.ib_lower_bound || ' - ' || ib.ib_upper_bound AS income_band
FROM RankedSales rs
JOIN income_band ib ON rs.hd_income_band_sk = ib.ib_income_band_sk
WHERE rs.rank_in_band <= 10
ORDER BY rs.hd_income_band_sk, rs.total_spent DESC;
