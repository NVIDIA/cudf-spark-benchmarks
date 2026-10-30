
WITH  sales_data AS (
    SELECT 
        ss_product_id,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(ss_ticket_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_product_id ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM (
        SELECT 
            ss_item_sk AS ss_product_id,
            ss_net_profit,
            ss_ticket_number
        FROM store_sales
        WHERE ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        UNION ALL
        SELECT 
            ws_item_sk AS ss_product_id,
            ws_net_profit,
            ws_order_number
        FROM web_sales
        WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    ) AS combined_sales
    GROUP BY ss_product_id
),
customer_stats AS (
    SELECT 
        customer.c_customer_sk,
        customer.c_first_name,
        customer.c_last_name,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(hd.hd_buy_potential, 'No Data') AS buy_potential,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_profit) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS rank
    FROM customer AS customer
    LEFT JOIN customer_demographics AS cd ON customer.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics AS hd ON customer.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_sales AS cs ON customer.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY customer.c_customer_sk, customer.c_first_name, customer.c_last_name, cd.cd_gender, hd.hd_buy_potential
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.gender,
        c.buy_potential,
        s.total_net_profit,
        s.total_sales
    FROM customer_stats AS c
    JOIN sales_data AS s ON c.c_customer_sk = s.ss_product_id
    WHERE c.rank <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    tc.total_sales,
    CASE 
        WHEN tc.total_net_profit IS NULL THEN 'No Purchases'
        ELSE CAST(tc.total_net_profit AS STRING)
    END AS purchase_statement
FROM top_customers AS tc
ORDER BY tc.total_net_profit DESC
LIMIT 50;
