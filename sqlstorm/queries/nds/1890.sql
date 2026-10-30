
WITH TotalSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 0
    GROUP BY ws.ws_item_sk
),
HighValueItems AS (
    SELECT
        ts.ws_item_sk,
        ts.total_net_paid,
        DENSE_RANK() OVER (ORDER BY ts.total_net_paid DESC) AS sales_rank
    FROM TotalSales ts
    WHERE ts.total_net_paid > 1000
),
BestCustomers AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS customer_spend,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        h.hd_income_band_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
    WHERE h.hd_income_band_sk IS NOT NULL
),
TopCustomers AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(bc.customer_spend) AS avg_spend,
        SUM(bc.total_orders) AS total_order_count,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM BestCustomers bc
    JOIN customer c ON bc.ws_bill_customer_sk = c.c_customer_sk
    JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT
    hvi.ws_item_sk,
    hvi.total_net_paid,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.avg_spend,
    tc.total_order_count,
    tc.customer_count
FROM HighValueItems hvi
JOIN TopCustomers tc ON tc.avg_spend > 500
ORDER BY hvi.total_net_paid DESC, tc.avg_spend DESC
LIMIT 50;
