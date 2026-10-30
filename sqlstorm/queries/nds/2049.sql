
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        COALESCE(su.average_sales_price, 0) AS average_sales_price
    FROM 
        item i
    LEFT JOIN (
        SELECT 
            ws_item_sk,
            AVG(ws_sales_price) AS average_sales_price
        FROM 
            web_sales
        GROUP BY 
            ws_item_sk
    ) su ON i.i_item_sk = su.ws_item_sk
),
CustomerStatistics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    id.i_item_id,
    id.i_product_name,
    id.i_brand,
    rs.SalesRank,
    cs.customer_count,
    cs.total_spent
FROM 
    RankedSales rs
JOIN 
    ItemDetails id ON rs.ws_item_sk = id.i_item_sk
LEFT JOIN 
    CustomerStatistics cs ON cs.customer_count > 0
WHERE 
    rs.SalesRank = 1 AND id.average_sales_price > (
        SELECT AVG(id2.average_sales_price) 
        FROM ItemDetails id2
    )
ORDER BY 
    cs.total_spent DESC
LIMIT 10;
