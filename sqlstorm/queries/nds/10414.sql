
SELECT 
    COUNT(*) AS total_sales,
    SUM(ws_net_profit) AS total_profit
FROM 
    web_sales
JOIN 
    customer ON ws_bill_customer_sk = c_customer_sk
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk
WHERE 
    cd_gender = 'F' 
    AND d_year = 2023
GROUP BY 
    cd_marital_status
ORDER BY 
    total_profit DESC;
