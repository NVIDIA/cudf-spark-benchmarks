
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN'
            WHEN cd.cd_purchase_estimate < 50 THEN 'LOW'
            WHEN cd.cd_purchase_estimate BETWEEN 50 AND 200 THEN 'MEDIUM'
            ELSE 'HIGH'
        END AS purchase_band,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
return_data AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), 
sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_paid) AS total_net_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.purchase_band,
    COALESCE(rd.total_returns, 0) AS total_returns,
    rd.total_return_amount,
    COALESCE(sd.total_sales, 0) AS total_sales,
    sd.total_net_sales,
    CASE 
        WHEN COALESCE(rd.total_returns, 0) > 0 THEN 'Returned'
        WHEN COALESCE(sd.total_sales, 0) > 1000 THEN 'High Sales'
        ELSE 'Normal'
    END AS sales_status
FROM 
    customer_stats cs
LEFT JOIN 
    return_data rd ON cs.c_customer_sk = rd.sr_item_sk
LEFT JOIN 
    sales_data sd ON cs.c_customer_sk = sd.ws_item_sk
WHERE 
    cs.rn = 1
    AND (cs.cd_gender = 'M' OR cs.cd_marital_status = 'S')
ORDER BY 
    cs.purchase_band DESC, cs.c_last_name, cs.c_first_name;
