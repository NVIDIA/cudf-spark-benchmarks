
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
PopularDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS customer_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales,
        pd.cd_gender,
        pd.cd_marital_status,
        pd.customer_count,
        pd.avg_net_profit
    FROM 
        RankedSales rs
    JOIN 
        PopularDemographics pd ON rs.sales_rank <= 10
    WHERE 
        rs.total_sales > 50000 
)
SELECT 
    ti.ws_item_sk,
    ti.total_sales,
    ti.cd_gender,
    ti.cd_marital_status,
    ti.customer_count,
    ti.avg_net_profit
FROM 
    TopSellingItems ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
WHERE 
    i.i_current_price > 20.00
ORDER BY 
    ti.total_sales DESC
LIMIT 20;
