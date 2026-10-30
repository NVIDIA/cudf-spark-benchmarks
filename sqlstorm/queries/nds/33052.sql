WITH  SalesCTE AS (
    SELECT
        ws_sold_date_sk,
        ws_ship_mode_sk,
        ws_item_sk,
        ws_order_number,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_mode_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (
        SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date) - INTERVAL '30 days'
    )
    GROUP BY ws_sold_date_sk, ws_ship_mode_sk, ws_item_sk, ws_order_number
),
TopSales AS (
    SELECT
        s.ws_sold_date_sk,
        sm.sm_ship_mode_id,
        SUM(s.total_sales) AS total_sales,
        SUM(s.order_count) AS total_orders
    FROM SalesCTE s
    JOIN ship_mode sm ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE s.rank <= 5
    GROUP BY s.ws_sold_date_sk, sm.sm_ship_mode_id
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT wo.ws_order_number) AS order_count,
        SUM(wo.ws_net_paid) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales wo ON c.c_customer_sk = wo.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.gender,
    ci.order_count,
    ci.total_spent,
    ts.total_sales,
    ts.total_orders
FROM CustomerInfo ci
LEFT JOIN TopSales ts ON ci.order_count > 0
ORDER BY ci.total_spent DESC, ts.total_sales DESC
LIMIT 10;