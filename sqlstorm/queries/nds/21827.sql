
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
),
TotalSales AS (
    SELECT 
        ss_item_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
SalesComparison AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_sales_price,
        r.ws_quantity,
        COALESCE(t.total_sales, 0) AS total_store_sales,
        COALESCE(t.transaction_count, 0) AS store_transaction_count,
        CASE 
            WHEN r.ws_sales_price > COALESCE(NULLIF(t.total_sales, 0) / NULLIF(t.transaction_count, 0), 0) THEN 'Above Average'
            WHEN r.ws_sales_price < COALESCE(NULLIF(t.total_sales, 0) / NULLIF(t.transaction_count, 0), 0) THEN 'Below Average'
            ELSE 'Average'
        END AS price_comparison
    FROM 
        RankedSales r
    LEFT JOIN 
        TotalSales t ON r.ws_item_sk = t.ss_item_sk
    WHERE 
        r.price_rank = 1
)
SELECT 
    sc.ws_item_sk,
    sc.ws_order_number,
    sc.ws_sales_price,
    sc.total_store_sales,
    sc.store_transaction_count,
    sc.price_comparison,
    CASE 
        WHEN sc.total_store_sales = 0 THEN 'No Store Sales'
        WHEN sc.store_transaction_count = 0 THEN 'No Transactions'
        ELSE 'Sales Data Available'
    END AS sales_data_status
FROM 
    SalesComparison sc
JOIN 
    customer c ON c.c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer WHERE c_current_cdemo_sk IS NOT NULL)
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
WHERE 
    CONCAT(ca.ca_city, ', ', ca.ca_state) IN ('New York, NY', 'Los Angeles, CA') 
    AND (ca.ca_country IS NULL OR ca.ca_country = 'USA')
ORDER BY 
    sc.ws_sales_price DESC
LIMIT 100;
