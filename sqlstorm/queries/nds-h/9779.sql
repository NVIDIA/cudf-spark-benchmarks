WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
OrderData AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        si.TotalSupplyCost
    FROM 
        SupplierInfo si
    JOIN 
        supplier s ON si.s_suppkey = s.s_suppkey
    ORDER BY 
        si.TotalSupplyCost DESC
    LIMIT 10
)
SELECT 
    od.o_orderkey,
    od.o_orderdate,
    od.TotalRevenue,
    ts.s_name,
    ts.TotalSupplyCost
FROM 
    OrderData od
JOIN 
    lineitem l ON od.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    l.l_shipdate >= '1996-01-01'
ORDER BY 
    od.TotalRevenue DESC;
