
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sales_price > 0
    GROUP BY 
        ss.ss_item_sk
),
CombinedSales AS (
    SELECT 
        rs.ws_item_sk,
        COALESCE(sss.total_quantity, 0) AS store_quantity,
        COALESCE(sss.total_net_paid, 0) AS store_net_paid,
        rs.ws_sales_price AS web_sales_price
    FROM 
        RankedSales rs
    LEFT JOIN 
        StoreSalesSummary sss ON rs.ws_item_sk = sss.ss_item_sk
    WHERE 
        rs.rn = 1
)
SELECT 
    i.i_item_id,
    cs.store_quantity,
    cs.store_net_paid,
    cs.web_sales_price,
    (cs.store_net_paid + cs.web_sales_price) AS total_revenue,
    CASE 
        WHEN cs.store_net_paid > 0 THEN 'Profitable'
        WHEN cs.web_sales_price > 0 THEN 'Potential Profit'
        ELSE 'No Revenue'
    END AS profitability_status
FROM 
    CombinedSales cs
JOIN 
    item i ON cs.ws_item_sk = i.i_item_sk
WHERE 
    cs.store_quantity > 10
ORDER BY 
    total_revenue DESC
LIMIT 50;
