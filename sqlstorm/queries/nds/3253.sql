
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
), 
TopItems AS (
    SELECT 
        ri.ws_item_sk,
        ri.total_quantity,
        ri.total_net_profit,
        i.i_item_desc
    FROM 
        RankedSales ri
    JOIN 
        item i ON ri.ws_item_sk = i.i_item_sk
    WHERE 
        ri.sales_rank <= 10
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        MAX(CASE WHEN cd.cd_gender = 'M' THEN cd.cd_purchase_estimate ELSE 0 END) AS male_purchase_estimate,
        MAX(CASE WHEN cd.cd_gender = 'F' THEN cd.cd_purchase_estimate ELSE 0 END) AS female_purchase_estimate
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_net_profit,
    cd.male_purchase_estimate,
    cd.female_purchase_estimate,
    (COALESCE(cd.male_purchase_estimate, 0) + COALESCE(cd.female_purchase_estimate, 0)) AS total_estimate,
    CASE 
        WHEN cd.male_purchase_estimate >= cd.female_purchase_estimate THEN 'Male Dominant'
        ELSE 'Female Dominant'
    END AS gender_dominance
FROM 
    TopItems ti
JOIN 
    CustomerDetails cd ON ti.ws_item_sk = cd.c_customer_sk
ORDER BY 
    ti.total_net_profit DESC;
