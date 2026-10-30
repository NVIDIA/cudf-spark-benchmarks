
WITH sales_summary AS (
    SELECT 
        d.d_year,
        cs.cs_item_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        d.d_year, cs.cs_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_online_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
inventory_levels AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    ss.d_year,
    ci.cd_gender,
    ci.cd_marital_status,
    ib.ib_income_band_sk,
    SUM(ss.total_sales) AS year_total_sales,
    SUM(ss.total_orders) AS year_total_orders,
    SUM(ss.total_profit) AS year_total_profit,
    AVG(ci.total_online_orders) AS avg_orders_per_customer,
    il.total_inventory
FROM 
    sales_summary ss
JOIN 
    customer_info ci ON ss.cs_item_sk IN (SELECT cs.cs_item_sk FROM catalog_sales cs WHERE cs.cs_item_sk IS NOT NULL)
JOIN 
    income_band ib ON ci.hd_income_band_sk = ib.ib_income_band_sk
JOIN 
    inventory_levels il ON ss.cs_item_sk = il.inv_item_sk
GROUP BY 
    ss.d_year, ci.cd_gender, ci.cd_marital_status, ib.ib_income_band_sk, il.total_inventory
ORDER BY 
    ss.d_year, ci.cd_gender, ib.ib_income_band_sk;
