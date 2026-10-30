
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458477 AND 2458530 
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        RankedSales.total_quantity,
        RankedSales.total_profit,
        RankedSales.ws_item_sk
    FROM 
        RankedSales
    JOIN 
        item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE 
        RankedSales.profit_rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status IN ('S', 'M') AND cd.cd_gender IS NOT NULL
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
SalesReturnDetails AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    TopItems.i_item_id,
    TopItems.i_product_name,
    COALESCE(SUM(SalesReturnDetails.total_returns), 0) AS returns,
    COALESCE(SUM(SalesReturnDetails.total_return_value), 0) AS return_value,
    CustomerDemographics.cd_gender,
    CustomerDemographics.cd_marital_status,
    CustomerDemographics.customer_count,
    CASE 
        WHEN CustomerDemographics.customer_count IS NULL THEN 'Unknown'
        ELSE 'Known'
    END AS customer_status
FROM 
    TopItems
LEFT JOIN 
    SalesReturnDetails ON TopItems.ws_item_sk = SalesReturnDetails.sr_item_sk
LEFT JOIN 
    CustomerDemographics ON CustomerDemographics.cd_gender = 
        (CASE 
            WHEN TopItems.total_profit > 1000 THEN 'M'
            ELSE 'S'
        END)
GROUP BY 
    TopItems.i_item_id, 
    TopItems.i_product_name, 
    CustomerDemographics.cd_gender, 
    CustomerDemographics.cd_marital_status, 
    CustomerDemographics.customer_count 
ORDER BY 
    returns DESC, 
    return_value DESC;
