
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        COS(0.5 * PI() * (ws.ws_sales_price / 100)) AS SalesImpact,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS PriceRank
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'M' 
        AND cd.cd_marital_status = 'S' 
        AND cd.cd_credit_rating = 'Low'
        AND ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231
),
TopSales AS (
    SELECT 
        rs.ws_item_sk AS ItemID,
        SUM(rs.ws_quantity) AS TotalSalesQuantity,
        AVG(rs.ws_sales_price) AS AveragePrice,
        MAX(rs.ws_sales_price) AS MAXSalesPrice,
        MIN(rs.ws_sales_price) AS MinSalesPrice
    FROM 
        RankedSales rs
    WHERE 
        rs.PriceRank <= 10
    GROUP BY 
        rs.ws_item_sk
)
SELECT 
    ts.ItemID,
    ts.TotalSalesQuantity,
    ts.AveragePrice,
    ts.MAXSalesPrice,
    ts.MinSalesPrice,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    TopSales ts
LEFT JOIN 
    customer c ON ts.ItemID = c.c_customer_sk 
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
WHERE 
    ca.ca_state IN ('NY', 'CA')
ORDER BY 
    ts.TotalSalesQuantity DESC
LIMIT 50;
