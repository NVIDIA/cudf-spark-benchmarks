
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
),
FinalReport AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        ws.avg_net_profit,
        ws.total_orders,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.ib_income_band_sk
    FROM 
        CustomerSales cs
    JOIN 
        WarehouseStats ws ON cs.c_customer_sk = ws.w_warehouse_sk
)

SELECT 
    f.cd_gender,
    f.cd_marital_status,
    f.ib_income_band_sk,
    COUNT(f.c_customer_sk) AS customer_count,
    AVG(f.total_sales) AS avg_sales_per_customer,
    AVG(f.order_count) AS avg_orders_per_customer,
    AVG(f.avg_net_profit) AS avg_net_profit_per_warehouse,
    SUM(f.total_orders) AS total_orders_by_income_band
FROM 
    FinalReport f
GROUP BY 
    f.cd_gender, f.cd_marital_status, f.ib_income_band_sk
ORDER BY 
    f.cd_gender, f.cd_marital_status, f.ib_income_band_sk;
