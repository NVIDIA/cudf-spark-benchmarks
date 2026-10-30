
WITH RankedSales AS (
    SELECT 
        ws_web_site_sk,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_web_site_sk
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_net_loss) AS total_loss
    FROM 
        web_returns
    WHERE 
        wr_order_number IN (SELECT DISTINCT ws_order_number FROM web_sales WHERE ws_net_paid > 100)
    GROUP BY 
        wr_returning_customer_sk
),
DetailedSales AS (
    SELECT 
        ws.ws_web_page_sk,
        ws.ws_item_sk,
        wp.wp_url,
        it.i_item_desc,
        ws.ws_net_paid,
        ws.ws_net_profit,
        CASE 
            WHEN ws.ws_net_paid IS NULL THEN 'No Sales'
            ELSE 'Sales Available'
        END AS sale_status,
        ws.ws_web_site_sk
    FROM 
        web_sales ws
    LEFT JOIN 
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN 
        item it ON ws.ws_item_sk = it.i_item_sk
)
SELECT 
    ds.ws_web_page_sk,
    ds.wp_url,
    ds.i_item_desc,
    ds.ws_net_paid,
    COALESCE(cr.total_loss, 0) AS total_return_loss,
    COALESCE(rs.total_net_paid, 0) AS web_sales_total,
    ds.sale_status
FROM 
    DetailedSales ds
LEFT JOIN 
    CustomerReturns cr ON ds.ws_web_site_sk = cr.wr_returning_customer_sk
LEFT JOIN 
    RankedSales rs ON ds.ws_web_site_sk = rs.ws_web_site_sk
WHERE 
    ds.ws_net_profit > 0
    OR ds.ws_net_paid IS NOT NULL
ORDER BY 
    ds.ws_net_paid DESC, 
    cr.total_loss DESC;
