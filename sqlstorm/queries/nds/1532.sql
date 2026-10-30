
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        d.d_date,
        SUM(s.ws_net_paid) AS total_spent,
        RANK() OVER (PARTITION BY d.d_month_seq ORDER BY SUM(s.ws_net_paid) DESC) AS rank_total_spent
    FROM customer c
    JOIN web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk
    JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
      AND c.c_current_cdemo_sk IS NOT NULL
    GROUP BY c.c_customer_id, d.d_date, d.d_month_seq
),
HighSpenders AS (
    SELECT 
        rc.c_customer_id,
        rc.total_spent
    FROM RankedCustomers rc
    WHERE rc.rank_total_spent <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(hd.hd_demo_sk) AS household_count,
        AVG(hd.hd_vehicle_count) AS avg_vehicles
    FROM household_demographics hd
    JOIN customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT 
    h.c_customer_id,
    h.total_spent,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.household_count,
    cd.avg_vehicles
FROM HighSpenders h
LEFT JOIN CustomerDemographics cd ON h.total_spent > 1000
WHERE cd.avg_vehicles IS NOT NULL
ORDER BY h.total_spent DESC
LIMIT 50;
