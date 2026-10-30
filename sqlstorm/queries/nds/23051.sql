WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_web_site_sk,
        ws.ws_item_sk, 
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2001
              AND d.d_month_seq IN (SELECT d_month_seq FROM date_dim WHERE d_year = 2001 AND d_dow BETWEEN 2 AND 5) 
        )
),
ProfitAnalysis AS (
    SELECT 
        r.ws_web_site_sk,
        SUM(r.ws_net_profit) AS total_profit,
        COUNT(r.ws_item_sk) AS item_count
    FROM 
        RankedSales r
    WHERE 
        r.profit_rank <= 5  
    GROUP BY 
        r.ws_web_site_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    cu.c_customer_sk,
    cu.c_first_name,
    cu.c_last_name,
    cu.gender,
    cu.cd_marital_status,
    cu.ca_city,
    cu.ca_state,
    CASE 
        WHEN pa.total_profit IS NULL THEN 'No Sales'
        WHEN pa.total_profit > 1000 THEN 'High Value'
        WHEN pa.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment,
    COALESCE(pa.total_profit, 0) AS total_profit,
    COALESCE(pa.item_count, 0) AS item_count
FROM 
    CustomerDetails cu
LEFT JOIN 
    ProfitAnalysis pa ON cu.c_customer_sk = pa.ws_web_site_sk
WHERE 
    cu.ca_city IS NOT NULL
    AND (cu.cd_marital_status = 'M' OR cu.ca_state = 'NY') 
ORDER BY 
    cu.c_last_name, 
    cu.c_first_name
LIMIT 20 OFFSET 10;