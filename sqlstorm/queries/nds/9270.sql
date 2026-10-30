
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_net_profit DESC) AS rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopProfitableItems AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        SUM(RankedSales.cs_net_profit) AS total_profit
    FROM 
        RankedSales
    JOIN 
        item ON RankedSales.cs_item_sk = item.i_item_sk
    WHERE 
        RankedSales.rank <= 5
    GROUP BY 
        item.i_item_id, item.i_product_name
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender AS gender,
        cd_marital_status,
        cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
SalesSummary AS (
    SELECT 
        td.d_year,
        cd.gender,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim td ON ws.ws_sold_date_sk = td.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        td.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        td.d_year, cd.gender
)
SELECT 
    p.i_item_id,
    p.i_product_name,
    s.d_year,
    s.gender,
    s.total_net_profit,
    s.total_customers,
    p.total_profit
FROM 
    SalesSummary s
JOIN 
    TopProfitableItems p ON p.total_profit > 10000
ORDER BY 
    s.d_year, s.gender, p.total_profit DESC;
