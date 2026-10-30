WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS SupplyValue,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    co.c_name,
    co.TotalSpent,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalLineItemValue,
    COUNT(DISTINCT ps.ps_suppkey) AS DistinctSuppliers,
    COUNT(DISTINCT p.p_partkey) AS DistinctParts,
    COALESCE(MAX(CASE WHEN co.TotalSpent > 1000 THEN 'High Roller' ELSE 'Regular' END), 'No Orders') AS CustomerType
FROM 
    CustomerOrders co
LEFT JOIN 
    orders o ON co.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    PartSupplierInfo ps ON l.l_partkey = ps.ps_partkey AND ps.rn = 1
LEFT JOIN 
    part p ON l.l_partkey = p.p_partkey
GROUP BY 
    co.c_name, co.TotalSpent
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 0
ORDER BY 
    TotalSpent DESC, TotalLineItemValue DESC;
