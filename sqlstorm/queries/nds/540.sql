
WITH SalesData AS (
    SELECT 
        s.ss_sold_date_sk,
        s.ss_item_sk,
        s.ss_quantity,
        s.ss_ext_sales_price,
        s.ss_net_paid
    FROM 
        store_sales s
    WHERE 
        s.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    UNION ALL
    SELECT 
        w.ws_sold_date_sk,
        w.ws_item_sk,
        w.ws_quantity,
        w.ws_ext_sales_price,
        w.ws_net_paid
    FROM 
        web_sales w
    WHERE 
        w.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
),
AggregatedSales AS (
    SELECT 
        sd.ss_sold_date_sk,
        sd.ss_item_sk,
        SUM(sd.ss_quantity) AS total_quantity,
        SUM(sd.ss_ext_sales_price) AS total_sales,
        SUM(sd.ss_net_paid) AS total_net_paid
    FROM 
        SalesData sd
    GROUP BY 
        sd.ss_sold_date_sk,
        sd.ss_item_sk
),
RankedSales AS (
    SELECT 
        asd.ss_item_sk,
        asd.total_quantity,
        asd.total_sales,
        asd.total_net_paid,
        RANK() OVER (PARTITION BY asd.ss_item_sk ORDER BY asd.total_sales DESC) AS sales_rank
    FROM 
        AggregatedSales asd
)
SELECT 
    is_item.i_item_id,
    is_item.i_item_desc,
    rs.total_quantity,
    rs.total_sales,
    rs.total_net_paid,
    CASE 
        WHEN rs.sales_rank = 1 THEN 'Top Seller'
        WHEN rs.sales_rank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS sales_category
FROM 
    RankedSales rs
JOIN 
    item is_item ON rs.ss_item_sk = is_item.i_item_sk
WHERE 
    is_item.i_current_price IS NOT NULL
    AND (rs.total_sales IS NOT NULL OR rs.total_net_paid IS NOT NULL)
ORDER BY 
    rs.total_sales DESC;
