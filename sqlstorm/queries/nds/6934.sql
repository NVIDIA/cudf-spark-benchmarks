
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND CAST(ws.ws_sold_date_sk AS INTEGER) BETWEEN 2021 AND 2023
    GROUP BY 
        c.c_customer_sk
), demographic_summary AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT s.s_store_sk) AS store_count,
        SUM(ss.total_quantity_sold) AS total_quantity_sold,
        SUM(ss.total_sales_amount) AS total_sales_amount,
        AVG(ss.total_orders) AS avg_orders_per_customer
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.c_customer_sk = c.c_customer_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN 
        store s ON c.c_current_addr_sk = s.s_store_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ds.store_count,
    ds.total_quantity_sold,
    ds.total_sales_amount,
    ds.avg_orders_per_customer
FROM 
    demographic_summary ds
JOIN 
    income_band ib ON ds.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    ib.ib_lower_bound;
