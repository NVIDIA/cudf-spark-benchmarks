
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rnk
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
filtered_sales AS (
    SELECT 
        ss.ws_sold_date_sk,
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        CASE 
            WHEN ss.total_sales > 1000 THEN 'High Value'
            WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS sales_category
    FROM sales_summary ss
    WHERE ss.rnk = 1
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(fs.total_sales) AS total_sales,
    AVG(fs.total_quantity) AS avg_quantity,
    CASE 
        WHEN AVG(fs.total_quantity) IS NULL THEN 'No Sales'
        WHEN AVG(fs.total_quantity) > 10 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_type
FROM filtered_sales fs
JOIN customer c ON c.c_customer_sk = fs.ws_item_sk 
JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk 
LEFT JOIN web_sales ws ON ws.ws_item_sk = fs.ws_item_sk
WHERE fs.total_sales > 500 OR (fs.total_sales IS NULL AND c.c_preferred_cust_flag = 'Y')
GROUP BY c.c_customer_id, ca.ca_city
ORDER BY total_sales DESC
LIMIT 10;
