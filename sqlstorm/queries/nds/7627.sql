
WITH sales_data AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year,
        w.w_warehouse_name,
        i.i_brand,
        i.i_category
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2023
),
aggregated_data AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        w_warehouse_name,
        i_category,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_net_profit) AS total_profit
    FROM sales_data
    GROUP BY 
        cd_gender,
        cd_marital_status,
        w_warehouse_name,
        i_category
),
ranked_data AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_profit DESC) AS profit_rank
    FROM aggregated_data
)
SELECT 
    cd_gender, 
    cd_marital_status, 
    w_warehouse_name, 
    i_category, 
    total_sales, 
    total_discount, 
    total_profit,
    profit_rank
FROM ranked_data
WHERE profit_rank <= 5
ORDER BY cd_gender, total_profit DESC;
