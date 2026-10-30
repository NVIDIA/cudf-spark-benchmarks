
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_sales_price,
        cs_quantity,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY cs_net_profit DESC) AS profit_rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND
                                (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopSellingItems AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_sales_price * cs_quantity) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
    HAVING 
        SUM(cs_quantity) > 1000
),
PopularDemographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    rs.cs_item_sk,
    tsi.total_quantity_sold,
    tsi.total_sales,
    pd.cd_gender,
    pd.customer_count,
    pd.total_profit
FROM 
    RankedSales rs
JOIN 
    TopSellingItems tsi ON rs.cs_item_sk = tsi.cs_item_sk
JOIN 
    PopularDemographics pd ON pd.customer_count > 50
WHERE 
    rs.profit_rank = 1
ORDER BY 
    pd.total_profit DESC
LIMIT 10;
