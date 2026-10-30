
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS order_count 
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
), 
BestSellingItems AS (
    SELECT 
        rs.ws_item_sk, 
        bi.i_item_desc, 
        bi.i_current_price, 
        rs.total_sales, 
        DENSE_RANK() OVER (ORDER BY rs.total_sales DESC) AS sales_rank
    FROM 
        RecursiveSales rs
    JOIN 
        item bi ON rs.ws_item_sk = bi.i_item_sk
), 
ItemPromotion AS (
    SELECT 
        bsi.ws_item_sk, 
        p.p_promo_id, 
        COUNT(p.p_promo_sk) AS promo_count 
    FROM 
        BestSellingItems bsi 
    LEFT JOIN 
        promotion p ON bsi.ws_item_sk = p.p_item_sk 
    GROUP BY 
        bsi.ws_item_sk, 
        p.p_promo_id 
    HAVING 
        COUNT(p.p_promo_sk) > 0
), 
SalesDate AS (
    SELECT 
        d.d_date, 
        d.d_month_seq, 
        d.d_year, 
        SUM(ws.ws_sales_price) AS total_web_sales 
    FROM 
        date_dim d 
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk 
    GROUP BY 
        d.d_date, 
        d.d_month_seq, 
        d.d_year
    HAVING 
        SUM(ws.ws_sales_price) > (SELECT AVG(ws2.ws_sales_price) FROM web_sales ws2)
)

SELECT 
    bsi.i_item_desc,
    bsi.total_sales,
    ip.p_promo_id,
    sd.d_year,
    sd.total_web_sales
FROM 
    BestSellingItems bsi 
LEFT JOIN 
    ItemPromotion ip ON bsi.ws_item_sk = ip.ws_item_sk 
JOIN 
    SalesDate sd ON bsi.ws_item_sk IN (SELECT cs_item_sk FROM catalog_sales WHERE cs_order_number IS NOT NULL)
WHERE 
    (ip.promo_count IS NULL OR ip.promo_count > 1)
    AND bsi.sales_rank <= 10
ORDER BY 
    sd.d_year DESC, 
    bsi.total_sales DESC;
