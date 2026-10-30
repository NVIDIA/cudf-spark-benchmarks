WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_quantity DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = cast('2002-10-01' as date))
),
TotalSales AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        COUNT(DISTINCT rs.ws_item_sk) AS unique_items,
        SUM(CASE WHEN rs.rank = 1 THEN 1 ELSE 0 END) AS highest_quantity_items
    FROM 
        RankedSales rs
    GROUP BY 
        rs.ws_order_number
),
CustomerCounts AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year < 1980 AND
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk
),
FinalReport AS (
    SELECT 
        tc.ws_order_number,
        tc.total_sales,
        cc.order_count,
        cc.total_quantity,
        cc.avg_sales_price
    FROM 
        TotalSales tc
    LEFT JOIN 
        CustomerCounts cc ON tc.ws_order_number = cc.order_count
)
SELECT 
    fr.ws_order_number,
    fr.total_sales,
    COALESCE(fr.order_count, 0) AS order_count,
    COALESCE(fr.total_quantity, 0) AS total_quantity,
    COALESCE(fr.avg_sales_price, 0.00) AS avg_sales_price
FROM 
    FinalReport fr
ORDER BY 
    fr.total_sales DESC
LIMIT 100;