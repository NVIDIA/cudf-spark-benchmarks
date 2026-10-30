
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 100
), HighPerformingItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        rs.total_quantity,
        rs.total_sales
    FROM 
        item i
    JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    WHERE 
        rs.sales_rank <= 10
), StoreSalesSummary AS (
    SELECT 
        s.s_store_id,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        SUM(ss_sales_price) AS total_revenue,
        AVG(ss_net_profit) AS average_profit
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_id
)
SELECT 
    hpi.i_item_id,
    hpi.i_product_name,
    sss.s_store_id,
    sss.total_transactions,
    sss.total_revenue,
    sss.average_profit
FROM 
    HighPerformingItems hpi
JOIN 
    StoreSalesSummary sss ON hpi.total_sales > sss.total_revenue
ORDER BY 
    hpi.total_sales DESC, sss.total_revenue DESC;
