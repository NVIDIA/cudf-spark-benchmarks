
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalValue
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
), 
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS recency_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1998-10-01' - INTERVAL '30 days'
)
SELECT  
    r.r_name AS RegionName,
    COUNT(DISTINCT c.c_custkey) AS UniqueCustomers,
    AVG(ps.ps_supplycost) AS AvgSupplyCost,
    COALESCE(SUM(l.l_discount), 0) AS TotalDiscounts,
    COUNT(DISTINCT lp.o_orderkey) AS LinkedOrders
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.Rank <= 5
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    RecentOrders lp ON l.l_orderkey = lp.o_orderkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey AND c.c_acctbal < 100
WHERE 
    r.r_comment IS NOT NULL
    AND c.c_custkey IS NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 0
    AND AVG(ps.ps_supplycost) IS NOT NULL
ORDER BY 
    UniqueCustomers DESC, 
    TotalDiscounts DESC;
