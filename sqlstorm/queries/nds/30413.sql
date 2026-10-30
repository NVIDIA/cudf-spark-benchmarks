
WITH  sales_data AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) AS rn
    FROM web_sales
    WHERE ws_sales_price > 50
),
customer_with_returns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT wr_order_number) AS return_count,
        SUM(wr_return_amt) AS total_return_amt,
        AVG(wr_return_quantity) AS avg_return_qty
    FROM customer c
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
premium_customers AS (
    SELECT 
        cd.cd_gender,
        SUM(sales_data.ws_quantity) AS total_sales_quantity,
        SUM(sales_data.ws_ext_sales_price) AS total_sales_value,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM sales_data
    JOIN customer c ON sales_data.ws_order_number = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Premium'
    GROUP BY cd.cd_gender
),
popular_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COUNT(DISTINCT ss_ticket_number) AS sales_count,
        SUM(ss_net_profit) AS total_net_profit
    FROM item i
    JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_id, i.i_item_desc
    HAVING SUM(ss_net_profit) > 1000
)
SELECT 
    pc.cd_gender,
    SUM(pc.total_sales_value) AS total_revenue,
    rt.return_count,
    rt.total_return_amt,
    pi.sales_count,
    pi.total_net_profit
FROM premium_customers pc
JOIN customer_with_returns rt ON pc.unique_customers > 0
LEFT JOIN popular_items pi ON pc.unique_customers = (SELECT COUNT(*) FROM customer)
GROUP BY pc.cd_gender, rt.return_count, rt.total_return_amt, pi.sales_count, pi.total_net_profit
HAVING SUM(pc.total_sales_value) > 50000
ORDER BY total_revenue DESC;
