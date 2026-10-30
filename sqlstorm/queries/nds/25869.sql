
WITH CustomerStoreInfo AS (
    SELECT 
        c.c_customer_id, 
        ca.ca_city, 
        ca.ca_state, 
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id, ca.ca_city, ca.ca_state
),
RankedCustomers AS (
    SELECT 
        csi.c_customer_id,
        csi.ca_city,
        csi.ca_state,
        csi.total_sales,
        csi.total_sales_amount,
        RANK() OVER (PARTITION BY csi.ca_state ORDER BY csi.total_sales_amount DESC) AS sales_rank
    FROM CustomerStoreInfo csi
)
SELECT 
    r.c_customer_id,
    r.ca_city,
    r.ca_state,
    r.total_sales,
    r.total_sales_amount,
    r.sales_rank,
    CASE 
        WHEN r.sales_rank <= 5 THEN 'Top 5'
        ELSE 'Others'
    END AS customer_group
FROM RankedCustomers r
WHERE r.total_sales_amount > 1000
ORDER BY r.ca_state, r.sales_rank;
