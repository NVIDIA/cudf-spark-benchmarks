
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        d.d_year,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, d.d_year, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS warehouse_sales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_id
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cs.total_orders,
    cs.avg_order_value,
    ws.warehouse_sales,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.ib_income_band_sk
FROM 
    customer_summary cs
JOIN 
    warehouse_sales ws ON cs.total_sales = ws.warehouse_sales
ORDER BY 
    cs.total_sales DESC
LIMIT 100;
