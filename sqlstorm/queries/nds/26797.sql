
WITH CustomerSales AS (
    SELECT 
        C.c_customer_sk,
        CONCAT(C.c_first_name, ' ', C.c_last_name) AS full_name,
        SUM(CASE 
            WHEN WS.ws_quantity IS NOT NULL THEN WS.ws_quantity 
            ELSE 0 
        END) AS total_quantity_sold,
        SUM(CASE 
            WHEN WS.ws_net_paid IS NOT NULL THEN WS.ws_net_paid 
            ELSE 0 
        END) AS total_net_paid,
        CD.cd_gender,
        CD.cd_marital_status,
        CD.cd_education_status
    FROM 
        customer C
    LEFT JOIN 
        web_sales WS ON C.c_customer_sk = WS.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
    GROUP BY 
        C.c_customer_sk, C.c_first_name, C.c_last_name, CD.cd_gender, CD.cd_marital_status, CD.cd_education_status
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_net_paid DESC) AS gender_rank
    FROM 
        CustomerSales
)
SELECT 
    full_name,
    total_quantity_sold,
    total_net_paid,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    gender_rank
FROM 
    RankedSales
WHERE 
    gender_rank <= 10
ORDER BY 
    cd_gender, total_net_paid DESC;
