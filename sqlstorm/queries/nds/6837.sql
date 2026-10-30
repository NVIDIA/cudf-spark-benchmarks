
WITH customer_data AS (
    SELECT 
        c.c_customer_id, 
        ca.ca_city, 
        cd.cd_gender,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND ca.ca_state = 'CA'
        AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY c.c_customer_id, ca.ca_city, cd.cd_gender
),
average_sales AS (
    SELECT 
        ca.ca_city,
        AVG(total_sales) AS avg_sales,
        AVG(total_transactions) AS avg_transactions
    FROM customer_data ca
    GROUP BY ca.ca_city
),
top_cities AS (
    SELECT 
        ca.ca_city,
        RANK() OVER (ORDER BY avg_sales DESC) AS sales_rank
    FROM average_sales ca
)
SELECT 
    tc.ca_city, 
    tc.sales_rank, 
    av.avg_sales,
    av.avg_transactions
FROM top_cities tc
JOIN average_sales av ON tc.ca_city = av.ca_city
WHERE tc.sales_rank <= 10
ORDER BY tc.sales_rank;
