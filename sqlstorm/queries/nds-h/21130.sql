
WITH RegionalSales AS (
    SELECT 
        n.n_name AS Nation_Name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY 
        n.n_name
), 

SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS Total_Cost,
        COUNT(DISTINCT p.p_partkey) AS Part_Count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY 
        s.s_suppkey, s.s_name
)

SELECT 
    r.Nation_Name,
    COALESCE(r.Total_Sales, 0) AS Yearly_Sales,
    COALESCE(s.Total_Cost, 0) AS Supplier_Cost,
    s.Part_Count,
    (CASE 
        WHEN COALESCE(r.Total_Sales, 0) > COALESCE(s.Total_Cost, 0) 
        THEN 'Sales Exceed Cost' 
        ELSE 'Cost Exceeds Sales' 
    END) AS Sales_Cost_Relationship
FROM 
    RegionalSales r
FULL OUTER JOIN 
    SupplierDetails s ON r.Nation_Name = s.s_name
ORDER BY 
    Yearly_Sales DESC,
    Supplier_Cost ASC;
