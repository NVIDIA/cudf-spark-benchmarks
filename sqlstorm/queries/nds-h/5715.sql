WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
    ORDER BY 
        TotalCost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND o.o_orderdate >= DATE '1997-01-01'
)
SELECT 
    r.r_name AS Region, 
    n.n_name AS Nation, 
    rs.s_name AS Supplier, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue
FROM 
    lineitem l
JOIN 
    RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey
JOIN 
    customerOrders co ON l.l_orderkey = co.o_orderkey
JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01' 
GROUP BY 
    r.r_name, n.n_name, rs.s_name
ORDER BY 
    Revenue DESC;