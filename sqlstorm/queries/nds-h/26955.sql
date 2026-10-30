WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_nationkey
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rn <= 5
),
MaxRetailPrice AS (
    SELECT 
        MAX(p.p_retailprice) AS max_price,
        p.p_type
    FROM 
        part p
    WHERE  
        p.p_size > 10
    GROUP BY 
        p.p_type
)
SELECT 
    c.c_name AS Customer_Name,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS Total_Sales,
    ns.n_name AS Nation_Name,
    ts.s_name AS Supplier_Name,
    mrp.max_price AS Highest_Retail_Price
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
JOIN 
    partsupp ps ON li.l_partkey = ps.ps_partkey
JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
JOIN 
    nation ns ON ts.s_nationkey = ns.n_nationkey
JOIN 
    MaxRetailPrice mrp ON li.l_partkey = ps.ps_partkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' 
    AND o.o_orderdate < DATE '1997-12-31'
GROUP BY 
    c.c_name, ns.n_name, ts.s_name, mrp.max_price
ORDER BY 
    Total_Sales DESC
LIMIT 10;