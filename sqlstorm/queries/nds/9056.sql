
SELECT 
    c.c_first_name AS First_Name,
    c.c_last_name AS Last_Name,
    SUM(ws.ws_quantity) AS Total_Quantity_Sold,
    SUM(ws.ws_net_paid_inc_tax) AS Total_Sales_Amount,
    cd.cd_gender AS Gender,
    CAST(d.d_date AS DATE) AS Sale_Date,
    w.w_warehouse_name AS Warehouse_Name
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE 
    d.d_year BETWEEN 2022 AND 2023
    AND cd.cd_gender = 'F'
GROUP BY 
    c.c_first_name, c.c_last_name, d.d_date, cd.cd_gender, w.w_warehouse_name
ORDER BY 
    Total_Sales_Amount DESC
LIMIT 50;
