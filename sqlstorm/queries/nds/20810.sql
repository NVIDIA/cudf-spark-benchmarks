
WITH customer_ranked AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        COALESCE(cd.cd_gender, 'UNKNOWN') AS gender,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        customer_ranked c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
    WHERE 
        c.purchase_rank <= 10
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
top_days AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date
    HAVING 
        SUM(ws.ws_sales_price) > (SELECT AVG(ws_ext_sales_price) FROM web_sales)
),
item_sales AS (
    SELECT
        i.i_item_id,
        SUM(CASE WHEN ws.ws_quantity > 0 THEN ws.ws_net_profit ELSE 0 END) AS total_profit,
        COUNT(ws.ws_order_number) AS sales_count
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
    HAVING 
        SUM(CASE WHEN ws.ws_quantity > 0 THEN ws.ws_net_profit ELSE 0 END) IS NOT NULL
)
SELECT 
    ch.total_sales,
    ts.total_sales AS day_sales,
    it.i_item_id,
    it.total_profit,
    (CASE WHEN it.sales_count > 100 THEN 'High Volume' ELSE 'Low Volume' END) AS sales_category
FROM 
    high_value_customers ch
JOIN 
    top_days ts ON (ch.gender = 'F' AND ts.total_sales > 5000) OR (ch.gender = 'M' AND ts.total_sales < 3000)
JOIN 
    item_sales it ON it.total_profit > 50 
WHERE 
    ch.total_sales IS NOT NULL
ORDER BY 
    ch.total_sales DESC, day_sales DESC;
