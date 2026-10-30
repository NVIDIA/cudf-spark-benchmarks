
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
),
SalesSummary AS (
    SELECT 
        rs.ws_item_sk,
        COUNT(*) AS total_sales,
        SUM(rs.ws_net_paid) AS total_net_paid,
        AVG(rs.ws_sales_price) AS avg_sales_price
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 10
    GROUP BY 
        rs.ws_item_sk
),
TopCustomers AS (
    SELECT 
        cs.ss_customer_sk,
        SUM(cs.ss_net_paid) AS cust_spent,
        COUNT(cs.ss_ticket_number) AS purchase_count,
        RANK() OVER (ORDER BY SUM(cs.ss_net_paid) DESC) AS cust_rank
    FROM 
        store_sales cs
    GROUP BY 
        cs.ss_customer_sk
)
SELECT 
    ca.ca_city,
    SUM(ss.total_net_paid) AS total_sales_value,
    COUNT(DISTINCT tc.ss_customer_sk) AS unique_customers,
    MAX(ss.avg_sales_price) AS max_avg_price,
    COALESCE(AVG(ss.total_sales), 0) AS avg_sales_per_item,
    CASE 
        WHEN MAX(ss.total_sales) IS NULL THEN 'No Sales'
        ELSE 'Sales Available'
    END AS sales_status
FROM 
    customer_address ca
LEFT JOIN 
    SalesSummary ss ON ss.ws_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_class_id NOT IN (SELECT DISTINCT i_class_id FROM item))
JOIN 
    TopCustomers tc ON tc.cust_spent > 1000
WHERE 
    ca.ca_state = 'CA'
GROUP BY 
    ca.ca_city
HAVING 
    SUM(ss.total_net_paid) > 5000
ORDER BY 
    total_sales_value DESC NULLS LAST;
