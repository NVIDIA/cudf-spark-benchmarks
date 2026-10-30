WITH  ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451545 AND 2451546  
    GROUP BY ws_item_sk
), item_prices AS (
    SELECT 
        i_item_sk,
        i_current_price,
        i_product_name
    FROM item
    WHERE i_rec_start_date <= cast('2002-10-01' as date) AND (i_rec_end_date IS NULL OR i_rec_end_date > cast('2002-10-01' as date))
), store_sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_net_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM store_sales
    GROUP BY ss_store_sk
), top_stores AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_city,
        s_zip,
        COALESCE(ss.total_net_sales, 0) AS total_net_sales
    FROM store s
    LEFT JOIN store_sales_summary ss ON s.s_store_sk = ss.ss_store_sk
), income_distribution AS (
    SELECT 
        hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM household_demographics hd
    JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY hd_income_band_sk
)
SELECT 
    ts.s_store_name,
    ts.s_city,
    ts.s_zip,
    ts.total_net_sales,
    COUNT(DISTINCT rs.ws_item_sk) AS items_sold,
    SUM(ip.i_current_price * rs.total_quantity) AS total_revenue,
    id.hd_income_band_sk,
    id.customer_count
FROM top_stores ts
LEFT JOIN ranked_sales rs ON ts.s_store_sk = rs.ws_item_sk
LEFT JOIN item_prices ip ON rs.ws_item_sk = ip.i_item_sk
LEFT JOIN income_distribution id ON id.hd_income_band_sk IN (1, 2)  
GROUP BY ts.s_store_name, ts.s_city, ts.s_zip, ts.total_net_sales, id.hd_income_band_sk, id.customer_count
HAVING SUM(ip.i_current_price * rs.total_quantity) > 5000  
ORDER BY total_net_sales DESC, items_sold DESC;