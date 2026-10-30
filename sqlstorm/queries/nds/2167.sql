
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER(PARTITION BY ws_bill_customer_sk ORDER BY ws_net_paid DESC) AS rnk
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS customer_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    SUM(rs.ws_quantity) AS total_quantity,
    SUM(rs.ws_net_paid) AS total_spent,
    ci.hd_income_band_sk
FROM CustomerInfo ci
JOIN RankedSales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
WHERE ci.customer_rank = 1
GROUP BY ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.hd_income_band_sk
HAVING SUM(rs.ws_net_paid) > (SELECT AVG(rs2.ws_net_paid) FROM RankedSales rs2)
ORDER BY total_spent DESC
LIMIT 10;
