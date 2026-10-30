
WITH  recent_sales AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
item_sales AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        SUM(COALESCE(rs.ws_net_paid, 0)) AS total_net_sales,
        COUNT(DISTINCT rs.ws_order_number) AS number_of_orders
    FROM 
        item i
    LEFT JOIN 
        recent_sales rs ON i.i_item_sk = rs.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
),
customer_info AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        date_dim d ON d.d_date_sk = ss.ss_sold_date_sk OR d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        c.c_customer_id, d.d_year
)
SELECT 
    ci.c_customer_id,
    ci.d_year,
    ci.store_orders,
    ci.total_store_sales,
    ci.total_web_sales,
    it.i_item_id,
    it.i_item_desc,
    it.total_net_sales,
    it.number_of_orders,
    (ci.total_store_sales + ci.total_web_sales) AS combined_sales,
    CASE 
        WHEN (ci.total_store_sales + ci.total_web_sales) IS NULL THEN 'No Sales'
        ELSE 'Total Sales Present'
    END AS sales_status
FROM 
    customer_info ci
JOIN 
    item_sales it ON ci.c_customer_id = it.i_item_id  -- this join condition should be corrected
WHERE 
    it.total_net_sales > 100
ORDER BY 
    combined_sales DESC
LIMIT 10;
