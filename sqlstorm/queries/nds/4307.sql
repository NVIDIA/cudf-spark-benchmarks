
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= 2456560 
), SalesSummary AS (
    SELECT 
        i.i_item_id,
        SUM(COALESCE(rs.ws_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT rs.ws_order_number) AS order_count
    FROM 
        item i
    LEFT JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.price_rank = 1
    GROUP BY 
        i.i_item_id
), HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(s.ss_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        s.ss_sold_date_sk BETWEEN 2456560 AND 2456568 
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(s.ss_net_paid) > 500
)
SELECT 
    s.i_item_id,
    s.total_sales,
    h.c_customer_id,
    h.total_spent
FROM 
    SalesSummary s
JOIN 
    HighValueCustomers h ON s.total_sales > 1000 
ORDER BY 
    s.total_sales DESC, h.total_spent DESC;
