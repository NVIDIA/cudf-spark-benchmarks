
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    JOIN 
        item ON ws_item_sk = i_item_sk
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND 
                               (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
BestSellingItems AS (
    SELECT 
        i_item_id,
        i_item_desc,
        ws_item_sk,
        total_quantity,
        total_net_profit
    FROM 
        RankedSales
    JOIN 
        item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE 
        rank <= 10
),
PurchasingDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(total_net_profit) AS total_spent
    FROM 
        BestSellingItems
    JOIN 
        web_sales ON BestSellingItems.ws_item_sk = web_sales.ws_item_sk
    JOIN 
        customer ON web_sales.ws_ship_customer_sk = customer.c_customer_sk
    JOIN 
        customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    customer_count,
    total_spent,
    ROUND(total_spent / customer_count, 2) AS avg_spent_per_customer
FROM 
    PurchasingDemographics
ORDER BY 
    total_spent DESC;
