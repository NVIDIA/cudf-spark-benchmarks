
WITH  CustomerCTE AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name,
        c.c_last_name,
        CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(ib.ib_lower_bound, 0) AS income_lower_bound,
        COALESCE(ib.ib_upper_bound, 1000000) AS income_upper_bound,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
),
SalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        CASE 
            WHEN SUM(ws.ws_net_paid) > 5000 THEN 'High'
            WHEN SUM(ws.ws_net_paid) BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'Low' 
        END AS sales_category
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    cte.c_customer_sk,
    cte.c_first_name,
    cte.c_last_name,
    cte.gender,
    cte.cd_marital_status,
    cte.cd_purchase_estimate,
    sd.total_quantity,
    sd.total_net_paid,
    sd.sales_category
FROM 
    CustomerCTE cte
FULL OUTER JOIN 
    SalesDetails sd ON cte.c_customer_sk = sd.ws_item_sk
WHERE 
    cte.purchase_rank <= 10 
    OR (sd.sales_category = 'High' AND cte.gender IS NOT NULL)
ORDER BY 
    COALESCE(cte.c_first_name, 'Unknown'),
    sd.total_net_paid DESC;
