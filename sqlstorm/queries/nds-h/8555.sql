
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        r.r_name
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, r.r_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r_name, 
        s_suppkey, 
        s_name, 
        s_acctbal, 
        total_supply_cost 
    FROM 
        RankedSuppliers 
    WHERE 
        rank = 1
)
SELECT 
    c.c_name, 
    c.c_acctbal, 
    t.r_name, 
    t.s_name, 
    t.total_supply_cost 
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    TopSuppliers t ON ps.ps_suppkey = t.s_suppkey
WHERE 
    o.o_orderstatus = 'O' 
    AND l.l_shipmode = 'AIR' 
    AND l.l_returnflag = 'N'
ORDER BY 
    t.total_supply_cost DESC, c.c_name;
