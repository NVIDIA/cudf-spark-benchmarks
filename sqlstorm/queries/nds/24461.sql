
WITH RecursiveSales AS (
    SELECT 
        ss_item_sk, 
        SUM(ss_sales_price) AS total_sales_price, 
        COUNT(DISTINCT ss_ticket_number) AS unique_sales_count
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
SalesRanked AS (
    SELECT 
        rs.ss_item_sk,
        rs.total_sales_price, 
        rs.unique_sales_count,
        DENSE_RANK() OVER (ORDER BY rs.total_sales_price DESC) AS sales_rank
    FROM 
        RecursiveSales rs
    WHERE rs.total_sales_price IS NOT NULL
),
TopSales AS (
    SELECT 
        sr.ss_item_sk,
        sr.total_sales_price,
        sr.unique_sales_count,
        COALESCE(sm.sm_type, 'Unknown') AS shipping_mode,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        SalesRanked sr
    LEFT JOIN 
        store s ON sr.ss_item_sk = s.s_store_sk
    LEFT JOIN 
        ship_mode sm ON sm.sm_ship_mode_sk = (SELECT sm_ship_mode_sk 
                                             FROM ship_mode 
                                             WHERE sm_carrier = 'UPS' 
                                             LIMIT 1)  
    JOIN 
        web_sales ws ON sr.ss_item_sk = ws.ws_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        sr.sales_rank <= 10
),
FinalResults AS (
    SELECT 
        ts.ss_item_sk,
        ts.total_sales_price,
        ts.unique_sales_count,
        ts.shipping_mode,
        CASE 
            WHEN ts.unique_sales_count > 50 THEN 'High Volume'
            WHEN ts.unique_sales_count BETWEEN 26 AND 50 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS sales_vol_category
    FROM 
        TopSales ts
    WHERE 
        ts.shipping_mode IS NOT NULL
)
SELECT 
    f.ss_item_sk,
    f.total_sales_price,
    f.unique_sales_count,
    f.shipping_mode,
    f.sales_vol_category,
    CONCAT('Sales for item: ', f.ss_item_sk, ' - ', f.shipping_mode) AS sales_info
FROM 
    FinalResults f
WHERE 
    f.total_sales_price > (
        SELECT AVG(total_sales_price) 
        FROM FinalResults 
        WHERE sales_vol_category = 'High Volume'
    )
ORDER BY 
    f.total_sales_price DESC
LIMIT 20;
