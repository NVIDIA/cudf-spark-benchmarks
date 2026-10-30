
WITH revenue_data AS (
    SELECT 
        w.w_warehouse_id,
        d.d_year,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        w.w_warehouse_id, d.d_year
), customer_segment AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 500
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    rd.w_warehouse_id,
    rd.d_year,
    rd.total_sales,
    rd.total_discount,
    rd.total_profit,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.customer_count
FROM 
    revenue_data AS rd
JOIN 
    customer_segment AS cs ON cs.customer_count > 0
ORDER BY 
    rd.w_warehouse_id, rd.d_year, cs.cd_gender, cs.cd_marital_status;
