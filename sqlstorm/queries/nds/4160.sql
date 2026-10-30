WITH CustomerRanked AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        CustomerRanked cr ON ws.ws_bill_customer_sk = cr.c_customer_sk
    WHERE 
        cr.gender_rank <= 10  
    GROUP BY 
        ws.ws_item_sk
),
TopProfitableItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        ROW_NUMBER() OVER (ORDER BY sd.total_net_profit DESC) AS item_rank
    FROM 
        SalesData sd
    WHERE 
        sd.total_net_profit IS NOT NULL
),
StoreDetails AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        COUNT(ss.ss_ticket_number) AS total_sales
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name, s.s_city, s.s_state
),
FinalReport AS (
    SELECT 
        tpi.ws_item_sk,
        tpi.total_quantity,
        tpi.total_net_profit,
        sd.total_sales,
        COALESCE(sd.total_sales, 0) * 1.0 / NULLIF(tpi.total_quantity, 0) AS sales_per_item
    FROM 
        TopProfitableItems tpi
    LEFT JOIN 
        StoreDetails sd ON tpi.ws_item_sk = sd.s_store_sk  
)
SELECT 
    fr.ws_item_sk,
    fr.total_quantity,
    fr.total_net_profit,
    fr.total_sales,
    fr.sales_per_item
FROM 
    FinalReport fr
WHERE 
    fr.total_net_profit > 1000 AND fr.total_sales > 5  
ORDER BY 
    fr.total_net_profit DESC, fr.total_quantity DESC;