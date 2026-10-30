
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
HighValueSales AS (
    SELECT 
        item.i_item_id,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        COUNT(DISTINCT rs.ws_order_number) AS order_count
    FROM 
        RankedSales rs
    INNER JOIN 
        item ON rs.ws_item_sk = item.i_item_sk
    WHERE 
        rs.rnk = 1
    GROUP BY 
        item.i_item_id
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cd.cd_gender, 'N/A') AS gender,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
IncomeSegment AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        customer c ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    COALESCE(cs.c_customer_id, 'Total') AS customer_id,
    cs.gender,
    hs.total_sales,
    cs.avg_sales_price,
    cs.total_orders,
    COALESCE(isg.customer_count, 0) AS income_segment_customer_count
FROM 
    CustomerStats cs
LEFT JOIN 
    HighValueSales hs ON cs.c_customer_id = hs.i_item_id
LEFT JOIN 
    IncomeSegment isg ON cs.total_orders > 0 
ORDER BY 
    hs.total_sales DESC NULLS LAST,
    cs.avg_sales_price DESC,
    cs.c_customer_id DESC
LIMIT 10 OFFSET 10;
