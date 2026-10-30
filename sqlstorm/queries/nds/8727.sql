
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_sales_amount,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(rs.total_sales_amount) AS total_sales_amount,
        SUM(rs.total_quantity_sold) AS total_quantity_sold
    FROM 
        RankedSales rs
    JOIN 
        web_sales ws ON rs.ws_item_sk = ws.ws_item_sk
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)

SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(SUM(sbd.total_sales_amount), 0) AS total_sales_amount,
    COALESCE(SUM(sbd.total_quantity_sold), 0) AS total_quantity_sold
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesByDemographics sbd ON cd.cd_gender = sbd.cd_gender AND cd.cd_marital_status = sbd.cd_marital_status
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_sales_amount DESC, total_quantity_sold DESC;
