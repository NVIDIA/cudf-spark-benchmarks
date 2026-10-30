
WITH  SalesCTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.ca_city,
        ad.ca_state,
        s.total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ad ON c.c_current_addr_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesCTE s ON s.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND ad.ca_city IS NOT NULL
), 
Ranking AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerDetails
)

SELECT 
    c_customer_id,
    cd_gender,
    cd_marital_status,
    ca_city,
    ca_state,
    total_sales
FROM 
    Ranking
WHERE 
    sales_rank <= 10
UNION ALL
SELECT 
    'N/A' AS c_customer_id,
    'N/A' AS cd_gender,
    'N/A' AS cd_marital_status,
    'N/A' AS ca_city,
    'N/A' AS ca_state,
    SUM(ss_net_paid) AS total_sales
FROM 
    store_sales
WHERE 
    ss_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
GROUP BY 
    ss_sold_date_sk
HAVING 
    SUM(ss_net_paid) IS NOT NULL;

