
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        d.d_year AS year,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        w.w_warehouse_name, d.d_year, cd.cd_gender, cd.cd_marital_status
),
ranked_sales AS (
    SELECT 
        inner_summary.year,
        inner_summary.w_warehouse_name,
        inner_summary.total_quantity_sold,
        inner_summary.total_sales,
        inner_summary.total_net_profit,
        inner_summary.cd_gender,
        inner_summary.cd_marital_status,
        RANK() OVER (PARTITION BY inner_summary.year ORDER BY inner_summary.total_sales DESC) AS sales_rank
    FROM 
        sales_summary AS inner_summary
)
SELECT 
    year,
    w_warehouse_name,
    total_quantity_sold,
    total_sales,
    total_net_profit,
    cd_gender,
    cd_marital_status
FROM 
    ranked_sales
WHERE 
    sales_rank <= 5
ORDER BY 
    year, total_sales DESC;
