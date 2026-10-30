
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales,
        w.w_warehouse_name,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        dd.d_year
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2020 AND 2022
),
total_sales AS (
    SELECT 
        r.ws_item_sk,
        SUM(r.ws_sales_price) AS total_sales_price
    FROM 
        ranked_sales r
    WHERE 
        r.rank_sales = 1 
    GROUP BY 
        r.ws_item_sk
)
SELECT 
    ts.ws_item_sk,
    ts.total_sales_price,
    MAX(r.w_warehouse_name) AS warehouse,
    COUNT(DISTINCT r.c_customer_id) AS total_customers,
    AVG(CASE 
            WHEN r.cd_gender = 'F' THEN 1 
            ELSE 0 
        END) AS female_ratio,
    COUNT(DISTINCT CASE 
            WHEN r.cd_marital_status = 'M' THEN r.c_customer_id 
            END) AS married_customers
FROM 
    total_sales ts
LEFT JOIN 
    ranked_sales r ON ts.ws_item_sk = r.ws_item_sk
GROUP BY 
    ts.ws_item_sk, ts.total_sales_price
HAVING 
    ts.total_sales_price > (SELECT AVG(ts2.total_sales_price) FROM total_sales ts2) 
ORDER BY 
    ts.total_sales_price DESC
LIMIT 10;
