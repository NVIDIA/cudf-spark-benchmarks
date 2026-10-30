
WITH sales_summary AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_ext_sales_price,
        cs.cs_ext_tax,
        cs.cs_net_profit,
        d.d_year,
        d.d_quarter_seq,
        d.d_month_seq,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        wd.w_warehouse_name,
        sm.sm_carrier,
        SUM(cs.cs_quantity) OVER (PARTITION BY cs.cs_item_sk ORDER BY d.d_date_sk) AS cumulative_quantity
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        warehouse wd ON cs.cs_warehouse_sk = wd.w_warehouse_sk
    JOIN 
        ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        d.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        cs.cs_sales_price > 50.00
)
SELECT 
    d_year, 
    d_quarter_seq, 
    COUNT(DISTINCT cs_item_sk) AS total_items_sold,
    SUM(cs_quantity) AS total_quantity_sold,
    SUM(cs_net_profit) AS total_net_profit,
    AVG(cumulative_quantity) AS avg_cumulative_quantity
FROM 
    sales_summary
GROUP BY 
    d_year, d_quarter_seq
ORDER BY 
    d_year, d_quarter_seq;
