
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        CD.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        CASE 
            WHEN cs.total_net_profit IS NULL THEN 'N/A'
            WHEN cs.total_net_profit < 1000 THEN 'Low'
            WHEN cs.total_net_profit BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS spending_category,
        COALESCE(cs.gender_rank, 0) AS rank_in_gender
    FROM 
        CustomerStats cs
    WHERE 
        cs.order_count > 5
),
OverlappingSales AS (
    SELECT 
        ws1.ws_sold_date_sk,
        ws1.ws_item_sk,
        COUNT(*) AS sale_count_for_item,
        SUM(ws1.ws_net_profit) AS total_net_profit_for_item
    FROM 
        web_sales ws1
    WHERE 
        ws1.ws_item_sk IN (SELECT DISTINCT cs.c_customer_sk FROM HighSpenders cs WHERE cs.spending_category = 'High')
    GROUP BY 
        ws1.ws_sold_date_sk, ws1.ws_item_sk
)
SELECT 
    hs.c_first_name,
    hs.c_last_name,
    hs.spending_category,
    os.sale_count_for_item,
    os.total_net_profit_for_item,
    CASE 
        WHEN os.total_net_profit_for_item IS NULL THEN 'No Sales'
        WHEN os.total_net_profit_for_item > 10000 THEN 'Very Profitable'
        ELSE 'Moderate Profit'
    END AS profit_status
FROM 
    HighSpenders hs
LEFT JOIN 
    OverlappingSales os ON hs.c_customer_sk = os.ws_item_sk
WHERE 
    hs.rank_in_gender = 1
ORDER BY 
    hs.spending_category, hs.c_first_name;
