
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
CustomerWithAddress AS (
    SELECT 
        c.c_customer_sk, 
        ca.ca_city, 
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    cwa.ca_city,
    cwa.ca_state,
    COUNT(DISTINCT cwa.c_customer_sk) AS customer_count,
    SUM(rs.total_sales) AS total_sales_amount,
    AVG(rs.total_quantity) AS avg_quantity_per_customer
FROM 
    CustomerWithAddress cwa
LEFT JOIN 
    RankedSales rs ON cwa.c_customer_sk = rs.ws_item_sk
WHERE 
    cwa.hd_income_band_sk IS NOT NULL 
    AND cwa.cd_gender = 'F'
    AND cwa.ca_state IN ('CA', 'NY')
GROUP BY 
    cwa.ca_city, 
    cwa.ca_state
HAVING 
    SUM(rs.total_sales) > 1000
ORDER BY 
    customer_count DESC;
