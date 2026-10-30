
WITH CTE_Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT CASE WHEN ws.ws_ship_date_sk IS NOT NULL THEN ws.ws_order_number END) AS shipped_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
CTE_Income_Bands AS (
    SELECT 
        h.hd_demo_sk,
        SUM(CASE 
            WHEN h.hd_income_band_sk IS NULL THEN 0 
            ELSE h.hd_income_band_sk 
        END) AS total_income_band,
        COUNT(h.hd_demo_sk) AS demographic_count
    FROM 
        household_demographics h 
    GROUP BY 
        h.hd_demo_sk
),
Max_Sales_Profit AS (
    SELECT 
        MAX(total_profit) AS max_profit
    FROM 
        CTE_Customer_Sales
),
CTE_Joined_Data AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_profit,
        ib.total_income_band,
        ib.demographic_count
    FROM 
        CTE_Customer_Sales cs
    JOIN 
        CTE_Income_Bands ib ON cs.c_customer_sk = ib.hd_demo_sk
)

SELECT 
    js.c_customer_sk,
    js.total_profit,
    js.total_income_band,
    js.demographic_count,
    CASE
        WHEN js.total_profit > (SELECT max_profit FROM Max_Sales_Profit) THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    CTE_Joined_Data js
LEFT JOIN 
    customer_demographics cd ON js.c_customer_sk = cd.cd_demo_sk
WHERE 
    (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F')
    AND (cd.cd_purchase_estimate IS NOT NULL OR js.demographic_count > 5)
ORDER BY 
    js.total_profit DESC
LIMIT 100;
