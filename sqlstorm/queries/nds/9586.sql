
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        ws.ws_item_sk, d.d_year, d.d_month_seq
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
product_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        MAX(i.i_current_price) AS max_price
    FROM 
        item i
    GROUP BY 
        i.i_item_sk, i.i_product_name, i.i_category
)
SELECT 
    cs.sales_year,
    cs.sales_month,
    ps.i_category,
    COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
    SUM(cs.total_quantity) AS total_quantity_sold,
    SUM(cs.total_sales) AS total_sales_amount,
    SUM(cs.total_profit) AS total_profit_margin,
    MAX(ps.max_price) AS highest_product_price
FROM 
    sales_data cs
JOIN 
    product_summary ps ON cs.ws_item_sk = ps.i_item_sk
LEFT JOIN 
    customer_data cd ON cs.ws_item_sk IN (SELECT sr_item_sk FROM store_returns WHERE sr_return_quantity > 0)
GROUP BY 
    cs.sales_year, cs.sales_month, ps.i_category
ORDER BY 
    cs.sales_year, cs.sales_month, total_sales_amount DESC;
