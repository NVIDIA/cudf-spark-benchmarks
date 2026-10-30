
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        ws_item_sk AS item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_amount,
        d_year,
        d_month_seq
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year BETWEEN 2022 AND 2023
    GROUP BY 
        ws_bill_customer_sk, ws_item_sk, d_year, d_month_seq
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
),
TopItems AS (
    SELECT 
        item_sk,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_amount DESC) AS rank
    FROM 
        SalesData
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ti.item_sk,
    sd.total_quantity,
    sd.total_amount
FROM 
    TopItems AS ti
JOIN 
    SalesData AS sd ON ti.item_sk = sd.item_sk
JOIN 
    CustomerDemographics AS cd ON sd.customer_sk = cd.c_customer_sk
WHERE 
    ti.rank <= 5
ORDER BY 
    sd.total_amount DESC, cd.cd_gender;
