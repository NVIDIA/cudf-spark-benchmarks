
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sales_price DESC) AS ranking
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2000000 AND 2000007
),
CustomerStatistics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        cd_gender
),
TopItems AS (
    SELECT 
        i_item_id,
        SUM(ws_quantity) AS total_sold
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.ranking <= 10
    GROUP BY 
        i_item_id
)
SELECT 
    cs.cd_gender,
    cs.total_customers,
    ROUND(cs.avg_purchase_estimate, 2) AS avg_purchase_estimate,
    ti.total_sold,
    CASE 
        WHEN ti.total_sold IS NULL THEN 'No sales'
        ELSE CONCAT('Sold ', ti.total_sold, ' items')
    END AS sales_report
FROM 
    CustomerStatistics cs
LEFT JOIN 
    TopItems ti ON TRUE
ORDER BY 
    cs.cd_gender;
