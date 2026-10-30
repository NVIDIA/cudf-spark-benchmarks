
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid_inc_tax,
        w.w_warehouse_name,
        d.d_date,
        d.d_month_seq,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_paid_inc_tax) AS total_net_paid
    FROM SalesData sd
    WHERE sd.rank <= 5
    GROUP BY sd.ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
),
Comparison AS (
    SELECT 
        ts.ws_item_sk,
        ts.total_quantity,
        ts.total_net_paid,
        cd.cd_gender,
        cd.cd_marital_status,
        (CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END) AS purchase_estimate_category
    FROM TopSales ts
    JOIN CustomerData cd ON ts.ws_item_sk = cd.c_customer_sk
)
SELECT 
    comp.ws_item_sk,
    comp.total_quantity,
    comp.total_net_paid,
    comp.cd_gender,
    comp.cd_marital_status,
    comp.purchase_estimate_category,
    RANK() OVER (ORDER BY comp.total_net_paid DESC) AS rank_by_sales
FROM Comparison comp
WHERE comp.total_net_paid IS NOT NULL
ORDER BY comp.total_net_paid DESC
LIMIT 10;

