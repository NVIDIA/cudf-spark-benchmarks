WITH  SalesCTE AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2001
    GROUP BY ws.ws_item_sk
),
NullCheck AS (
    SELECT 
        s.ss_item_sk,
        COUNT(s.ss_ticket_number) AS total_sales_tickets,
        COALESCE(MAX(s.ss_sales_price), 0) AS max_price,
        COUNT(DISTINCT s.ss_customer_sk) AS unique_customers,
        s.ss_item_sk = NULL AS is_null_check 
    FROM store_sales s
    GROUP BY s.ss_item_sk
),
CombinedSales AS (
    SELECT
        c.ws_item_sk,
        c.total_quantity,
        c.total_sales,
        n.total_sales_tickets,
        n.max_price,
        n.unique_customers,
        c.sales_rank,
        CASE 
            WHEN n.total_sales_tickets IS NULL THEN 'No Store Sales'
            WHEN c.total_sales < 1000 THEN 'Low Sales'
            ELSE 'Good Sales'
        END AS sales_category
    FROM SalesCTE c
    LEFT JOIN NullCheck n ON c.ws_item_sk = n.ss_item_sk
)
SELECT 
    cs.ws_item_sk,
    cs.total_quantity,
    cs.total_sales,
    cs.total_sales_tickets,
    cs.max_price,
    cs.unique_customers,
    cs.sales_rank,
    cs.sales_category,
    CASE 
        WHEN cs.sales_rank = 1 THEN 'Top Seller'
        WHEN cs.sales_rank IS NULL THEN 'No Sales Data'
        ELSE 'Average Seller'
    END AS seller_status
FROM CombinedSales cs
WHERE cs.sales_category IN ('Good Sales', 'Low Sales')
ORDER BY cs.total_sales DESC NULLS LAST;