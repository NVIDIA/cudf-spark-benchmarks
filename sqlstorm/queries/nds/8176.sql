WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459580 AND 2459586 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, 
        cd.cd_purchase_estimate, hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
), sales_analysis AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales_value,
        COUNT(cs.cs_order_number) AS total_orders
    FROM 
        catalog_sales AS cs
    WHERE 
        cs.cs_sold_date_sk BETWEEN 2459580 AND 2459586 
    GROUP BY 
        cs.cs_item_sk
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    cu.cd_gender,
    cu.cd_marital_status,
    cu.total_sales,
    cu.order_count,
    sa.total_sales_value,
    sa.total_orders
FROM 
    customer_summary AS cu
JOIN sales_analysis AS sa ON cu.c_customer_sk = sa.cs_item_sk
ORDER BY 
    cu.total_sales DESC, sa.total_sales_value DESC
LIMIT 100;