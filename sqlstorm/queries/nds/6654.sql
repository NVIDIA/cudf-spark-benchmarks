
WITH RankedSales AS (
    SELECT 
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_sales_price,
        cs.cs_quantity,
        RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_net_profit DESC) AS profit_rank,
        d.d_month_seq,
        d.d_year
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
),
TopSellingItems AS (
    SELECT 
        item.i_item_id,
        SUM(rs.cs_sales_price * rs.cs_quantity) AS total_sales,
        SUM(rs.cs_quantity) AS total_quantity
    FROM 
        RankedSales rs
    JOIN 
        item item ON rs.cs_item_sk = item.i_item_sk
    WHERE 
        rs.profit_rank <= 5
    GROUP BY 
        item.i_item_id
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
FinalResults AS (
    SELECT 
        cdem.cd_gender,
        cdem.cd_marital_status,
        cdem.cd_education_status,
        tsi.total_sales,
        tsi.total_quantity,
        cdem.total_net_profit
    FROM 
        CustomerDemographics cdem
    JOIN 
        TopSellingItems tsi ON cdem.total_net_profit > 1000
    ORDER BY 
        tsi.total_sales DESC
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    SUM(fr.total_sales) AS total_sales,
    SUM(fr.total_net_profit) AS total_profit
FROM 
    FinalResults fr
JOIN 
    CustomerDemographics cd ON fr.cd_gender = cd.cd_gender
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
HAVING 
    SUM(fr.total_sales) > 5000
ORDER BY 
    total_profit DESC;
