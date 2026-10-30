
WITH SalesSummary AS (
    SELECT
        d.d_year,
        d.d_moy,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY d.d_year, d.d_moy
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
WarehouseSummary AS (
    SELECT
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS orders_handled,
        SUM(ws.ws_net_profit) AS total_profit
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_id
)
SELECT
    ss.d_year,
    ss.d_moy,
    ss.total_sales,
    ss.total_quantity,
    ss.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.avg_purchase_estimate,
    ws.w_warehouse_id,
    ws.orders_handled,
    ws.total_profit
FROM SalesSummary ss
JOIN CustomerDemographics cd ON ss.total_sales >= 1000
JOIN WarehouseSummary ws ON ws.orders_handled > 10
ORDER BY ss.d_year, ss.d_moy, cd.cd_gender, ws.total_profit DESC;
