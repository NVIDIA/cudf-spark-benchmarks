
WITH  customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(CASE WHEN ss.ss_sales_price IS NOT NULL THEN ss.ss_sales_price ELSE 0 END) AS total_sales,
        COUNT(ss.ss_ticket_number) AS purchase_count,
        AVG(ss.ss_sales_price) AS avg_sale_price,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ss.ss_net_profit) DESC) AS rank
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
aggregate_sales AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.purchase_count,
        cs.avg_sale_price,
        MAX(cs.rank) AS max_rank,
        CASE 
            WHEN MAX(cs.total_sales) IS NULL THEN 'No Sales'
            WHEN MAX(cs.avg_sale_price) IS NULL THEN 'Avg Price Unknown'
            ELSE 'Active Customer'
        END AS customer_status
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    GROUP BY c.c_customer_id, cs.total_sales, cs.purchase_count, cs.avg_sale_price
),
sales_statistics AS (
    SELECT 
        customer_status,
        COUNT(*) AS customer_count,
        SUM(total_sales) AS total_sales_sum,
        AVG(avg_sale_price) AS average_sale_price
    FROM aggregate_sales
    GROUP BY customer_status
)
SELECT 
    a.customer_status,
    a.customer_count,
    a.total_sales_sum,
    a.average_sale_price,
    (SELECT COUNT(*) FROM customer) AS total_customers,
    (SELECT COUNT(DISTINCT wr_item_sk) FROM web_returns WHERE wr_return_quantity > 0) AS total_web_returns,
    CASE 
        WHEN a.customer_count = 0 THEN 'No Customers'
        ELSE 'Statistics Available'
    END AS availability
FROM sales_statistics a
FULL OUTER JOIN (SELECT DISTINCT ca_state FROM customer_address) addr ON TRUE
WHERE addr.ca_state IS NOT NULL OR a.customer_count > 5
ORDER BY a.total_sales_sum DESC NULLS LAST;
