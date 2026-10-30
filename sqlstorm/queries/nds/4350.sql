
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS sale_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451549  
), SalesSummary AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        COUNT(DISTINCT rs.ws_item_sk) AS unique_items,
        MIN(rs.ws_sales_price) AS min_price,
        MAX(rs.ws_sales_price) AS max_price
    FROM 
        RankedSales rs
    WHERE 
        rs.sale_rank <= 3  
    GROUP BY 
        rs.ws_order_number
), CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT s.ss_ticket_number) AS store_sales_count,
        SUM(s.ss_net_paid) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
), TotalSales AS (
    SELECT 
        ss.ws_order_number,
        ss.total_sales,
        cs.total_store_sales,
        cs.store_sales_count
    FROM 
        SalesSummary ss
    LEFT JOIN 
        CustomerData cs ON cs.store_sales_count > 0
)
SELECT 
    ts.ws_order_number,
    ts.total_sales,
    ts.store_sales_count,
    COALESCE(ts.total_store_sales, 0) AS total_store_sales,
    (ts.total_sales - COALESCE(ts.total_store_sales, 0)) AS online_vs_store_sales_diff
FROM 
    TotalSales ts
WHERE 
    ts.total_sales > 1000
ORDER BY 
    online_vs_store_sales_diff DESC
LIMIT 10;
