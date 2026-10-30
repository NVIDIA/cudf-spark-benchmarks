
WITH DateRange AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_date BETWEEN '2022-01-01' AND '2022-12-31'
),
CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM DateRange)
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
WarehouseSales AS (
    SELECT
        w.w_warehouse_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM DateRange)
    GROUP BY w.w_warehouse_id
)
SELECT
    cs.c_customer_id,
    cs.total_sales,
    cs.order_count,
    cs.last_purchase_date,
    ws.w_warehouse_id,
    ws.total_orders,
    ws.total_revenue,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.ib_income_band_sk
FROM CustomerSales cs
LEFT JOIN WarehouseSales ws ON cs.total_sales > 5000
ORDER BY cs.total_sales DESC, ws.total_revenue DESC;
