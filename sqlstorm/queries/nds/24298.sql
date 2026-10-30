
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
),
TotalReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        COUNT(DISTINCT cr_order_number) AS orders_returned
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
CustomerStatistics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
FilteredSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price,
        ts.total_returns,
        cs.total_orders,
        cs.total_spent
    FROM 
        RankedSales rs
    LEFT JOIN 
        TotalReturns ts ON rs.ws_item_sk = ts.cr_item_sk
    LEFT JOIN 
        CustomerStatistics cs ON rs.ws_order_number IN (SELECT DISTINCT ws_order_number FROM web_sales)
    WHERE 
        (ts.total_returns IS NULL OR ts.total_returns < 5) AND 
        cs.total_spent > 100
)
SELECT 
    fs.ws_order_number,
    fs.ws_item_sk,
    fs.ws_sales_price,
    COALESCE(fs.total_returns, 0) AS total_returns,
    COALESCE(fs.total_orders, 0) AS total_orders,
    COALESCE(fs.total_spent, 0) AS total_spent,
    (CASE 
        WHEN fs.total_spent > 500 THEN 'VIP'
        WHEN fs.total_spent BETWEEN 300 AND 500 THEN 'Premium'
        ELSE 'Regular'
    END) AS customer_status
FROM 
    FilteredSales fs
WHERE 
    (fs.ws_sales_price IS NOT NULL AND fs.ws_sales_price > 0) 
ORDER BY 
    fs.ws_sales_price DESC, fs.ws_order_number;
