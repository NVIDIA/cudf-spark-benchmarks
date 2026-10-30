
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sales_price) AS max_price,
        MIN(ws.ws_sales_price) AS min_price,
        w.w_warehouse_name,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk, w.w_warehouse_name, c.c_first_name, c.c_last_name, cd.cd_gender
),
sales_ranked AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY w_warehouse_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    sr.w_warehouse_name,
    sr.total_quantity,
    sr.total_sales,
    sr.order_count,
    sr.max_price,
    sr.min_price,
    sr.c_first_name,
    sr.c_last_name,
    sr.cd_gender
FROM 
    sales_ranked sr
WHERE 
    sr.sales_rank <= 10
ORDER BY 
    sr.w_warehouse_name, sr.total_sales DESC;
