
SELECT 
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
    MAX(d.d_year) AS latest_year,
    MIN(d.d_year) AS earliest_year
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023
GROUP BY 
    d.d_year
ORDER BY 
    d.d_year;
