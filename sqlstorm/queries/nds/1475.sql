
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate < 5000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 5000 AND 15000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_band
    FROM 
        customer_demographics cd
),
TopProducts AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        sd.total_quantity_sold,
        sd.total_net_profit
    FROM 
        item i
    JOIN 
        SalesData sd ON i.i_item_sk = sd.ws_item_sk
    WHERE 
        sd.profit_rank <= 10
)
SELECT 
    tp.i_item_id,
    tp.i_item_desc,
    tp.total_quantity_sold,
    tp.total_net_profit,
    cd.purchase_band,
    (SELECT COUNT(*) FROM customer c WHERE c.c_current_cdemo_sk = cd.cd_demo_sk) AS customer_count
FROM 
    TopProducts tp
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_current_addr_sk IS NOT NULL LIMIT 1)
WHERE 
    tp.total_net_profit > 0
ORDER BY 
    tp.total_net_profit DESC;
