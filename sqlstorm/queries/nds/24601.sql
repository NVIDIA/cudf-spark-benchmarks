
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk, 
        ss_item_sk
),
TopSellingItems AS (
    SELECT 
        rs.ss_store_sk,
        rs.ss_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
),
TotalSalesByStore AS (
    SELECT 
        ss_store_sk,
        SUM(total_sales) AS store_total_sales
    FROM 
        TopSellingItems
    GROUP BY 
        ss_store_sk
),
SalesDetails AS (
    SELECT 
        tssi.ss_store_sk,
        tssi.ss_item_sk,
        tssi.total_sales,
        tsb.store_total_sales,
        CASE 
            WHEN tssi.total_sales = 0 THEN NULL 
            ELSE ROUND((tssi.total_sales / tsb.store_total_sales) * 100, 2) 
        END AS sales_percentage
    FROM 
        TopSellingItems tssi
    JOIN 
        TotalSalesByStore tsb ON tssi.ss_store_sk = tsb.ss_store_sk
)
SELECT 
    ws.web_site_id,
    ca.ca_city,
    COALESCE(SUM(sd.total_sales), 0) AS total_sales_contributed,
    COALESCE(AVG(sd.sales_percentage), 0) AS avg_percentage_of_sales,
    COUNT(DISTINCT sd.ss_item_sk) AS distinct_items_sold
FROM 
    web_site ws
LEFT JOIN 
    store s ON ws.web_site_sk = s.s_store_sk
LEFT JOIN 
    SalesDetails sd ON s.s_store_sk = sd.ss_store_sk
LEFT JOIN 
    customer_address ca ON s.s_store_sk = ca.ca_address_sk
GROUP BY 
    ws.web_site_id, 
    ca.ca_city
HAVING 
    AVG(COALESCE(sd.sales_percentage, 0)) > 50 
    OR COUNT(DISTINCT sd.ss_item_sk) > 10
ORDER BY 
    total_sales_contributed DESC, 
    avg_percentage_of_sales ASC;
