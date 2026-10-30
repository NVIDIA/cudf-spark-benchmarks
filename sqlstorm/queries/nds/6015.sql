WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) as rank
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001 AND 
        dd.d_moy IN (5, 6) 
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) as total_quantity,
        SUM(rs.ws_net_paid) as total_net_paid
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5
    GROUP BY 
        rs.ws_item_sk
    ORDER BY 
        total_quantity DESC
    LIMIT 10
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    tsi.total_quantity,
    tsi.total_net_paid
FROM 
    TopSellingItems tsi
JOIN 
    item i ON tsi.ws_item_sk = i.i_item_sk
JOIN 
    promotion p ON i.i_item_sk = p.p_item_sk
WHERE 
    p.p_discount_active = 'Y'
ORDER BY 
    tsi.total_net_paid DESC;