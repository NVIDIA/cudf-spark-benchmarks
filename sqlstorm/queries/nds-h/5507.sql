WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
HighestRankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.nation_name,
        r.total_supply_cost
    FROM 
        RankedSuppliers r
    JOIN 
        supplier s ON r.s_suppkey = s.s_suppkey
    WHERE 
        r.rank = 1
)
SELECT 
    c.c_custkey,
    c.c_name,
    o.o_orderkey,
    COUNT(DISTINCT l.l_orderkey) AS number_of_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    h.nation_name,
    h.total_supply_cost
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    HighestRankedSuppliers h ON l.l_suppkey = h.s_suppkey
WHERE 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    c.c_custkey, c.c_name, o.o_orderkey, h.nation_name, h.total_supply_cost
ORDER BY 
    total_revenue DESC
LIMIT 100;