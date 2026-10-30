WITH AggregateReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returned_quantity, 
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(distinct sr_ticket_number) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(ar.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(ar.total_return_amount, 0) AS total_return_amount
    FROM 
        item i
    LEFT JOIN 
        AggregateReturns ar ON i.i_item_sk = ar.sr_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer_demographics cd 
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
SalesSummary AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= 2459596 
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    id.i_item_desc,
    id.i_current_price,
    id.total_returned_quantity,
    id.total_return_amount,
    COALESCE(ss.total_sales_quantity, 0) AS total_sales_quantity,
    COALESCE(ss.total_net_profit, 0) AS total_net_profit,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    ItemDetails id
LEFT JOIN 
    SalesSummary ss ON id.i_item_sk = ss.ws_item_sk
LEFT JOIN 
    CustomerDemographics cd ON cd.rank = 1 
WHERE 
    (id.total_returned_quantity > 0 OR ss.total_sales_quantity IS NOT NULL)
ORDER BY 
    id.total_return_amount DESC, id.i_current_price;