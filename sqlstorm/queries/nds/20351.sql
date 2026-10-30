WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_sales_price, 
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS Rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL AND
        ws.ws_sales_price > 0
), 
TotalSales AS (
    SELECT 
        rs.ws_item_sk, 
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_revenue
    FROM 
        RankedSales rs
    WHERE 
        rs.Rank <= 10
    GROUP BY 
        rs.ws_item_sk
), 
ItemDetails AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        i.i_item_desc,
        COALESCE(ts.total_revenue, 0) AS total_revenue
    FROM 
        item i
    LEFT JOIN 
        TotalSales ts ON i.i_item_sk = ts.ws_item_sk
), 
HighRevenueItems AS (
    SELECT 
        id.*, 
        DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        ItemDetails id
    WHERE 
        id.total_revenue > (SELECT AVG(total_revenue) FROM ItemDetails) 
)

SELECT 
    hi.i_item_id,
    hi.i_item_desc,
    hi.total_revenue,
    CASE 
        WHEN hi.revenue_rank <= 5 THEN 'Top Performer'
        WHEN hi.revenue_rank <= 10 THEN 'Good Performer'
        ELSE 'Average Performer'
    END AS performance_category,
    (SELECT COUNT(DISTINCT c.c_customer_id) 
     FROM customer c 
     WHERE c.c_current_cdemo_sk IN (
         SELECT cd.cd_demo_sk 
         FROM customer_demographics cd 
         WHERE cd.cd_credit_rating = 'Good'
     )) AS good_credit_customers_count
FROM 
    HighRevenueItems hi
WHERE 
    hi.revenue_rank <= 10
ORDER BY 
    hi.total_revenue DESC;