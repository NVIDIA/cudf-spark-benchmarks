
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS spender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458498 AND 2458550  
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
HighSpenders AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.total_spent,
        rc.spender_rank,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        RankedCustomers rc
    JOIN 
        household_demographics hd ON rc.c_customer_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        rc.spender_rank <= 10  
)
SELECT 
    h.c_customer_sk,
    h.c_first_name,
    h.c_last_name,
    h.total_spent,
    h.spender_rank,
    CONCAT('$', CAST(ROUND(h.total_spent, 2) AS STRING)) AS formatted_spent,
    CONCAT('$', CAST(ROUND(h.ib_lower_bound, 2) AS STRING), ' - $', CAST(ROUND(h.ib_upper_bound, 2) AS STRING)) AS income_band
FROM 
    HighSpenders h
ORDER BY 
    h.spender_rank, h.c_last_name, h.c_first_name;
