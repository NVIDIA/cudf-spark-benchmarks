WITH SalesData AS (
    SELECT 
        ws_sales_price,
        ws_quantity,
        ws_bill_customer_sk,
        ws_sold_date_sk,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sold_date_sk DESC) AS SalesRank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459000 AND 2459005
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    COUNT(sd.ws_sales_price) AS total_sales_count,
    SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales_amount,
    STRING_AGG(DISTINCT cd.hd_buy_potential) AS distinct_buy_potentials
FROM 
    CustomerData cd
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    cd.hd_income_band_sk IS NOT NULL 
    AND cd.cd_gender = 'F'
GROUP BY 
    cd.c_first_name, cd.c_last_name
HAVING 
    COUNT(sd.ws_sales_price) > 1
ORDER BY 
    total_sales_amount DESC
LIMIT 10;