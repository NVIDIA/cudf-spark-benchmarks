WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY nation ORDER BY total_supply_cost DESC) AS rank
    FROM 
        RankedSuppliers
)
SELECT 
    c.c_name,
    c.c_acctbal,
    o.o_orderkey,
    o.o_orderdate,
    l.l_quantity,
    l.l_extendedprice,
    ts.s_name,
    ts.total_supply_cost
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    ts.rank <= 5 AND 
    o.o_orderdate >= '1997-01-01' AND 
    l.l_shipmode = 'AIR'
ORDER BY 
    ts.total_supply_cost DESC, 
    o.o_orderdate ASC;