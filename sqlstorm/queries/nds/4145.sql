
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
customer_stats AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.total_orders,
        cs.net_profit,
        RANK() OVER (ORDER BY cs.net_profit DESC) AS customer_rank
    FROM 
        customer_stats cs
),
item_categories AS (
    SELECT 
        i.i_item_sk,
        i.i_category,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM 
        item i 
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        i.i_item_sk, i.i_category
)

SELECT 
    tci.i_item_sk,
    tci.i_category,
    tci.unique_customers,
    ss.total_quantity,
    ss.total_sales,
    tc.c_customer_sk,
    tc.cd_gender,
    tc.total_orders,
    tc.net_profit
FROM 
    item_categories tci
JOIN 
    sales_summary ss ON tci.i_item_sk = ss.ws_item_sk
JOIN 
    top_customers tc ON tc.customer_rank <= 10 
WHERE 
    ss.sales_rank = 1 
    AND tci.unique_customers > 5 
ORDER BY 
    ss.total_sales DESC, tc.net_profit DESC;
