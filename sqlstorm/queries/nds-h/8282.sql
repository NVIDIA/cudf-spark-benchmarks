WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY pn.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation pn ON s.s_nationkey = pn.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, pn.n_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.total_supply_cost
    FROM 
        RankedSuppliers r
    JOIN 
        supplier s ON r.s_suppkey = s.s_suppkey
    WHERE 
        r.rank <= 5
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.c_address,
    o.o_orderkey,
    o.o_orderstatus,
    o.o_totalprice,
    l.l_orderkey,
    l.l_partkey,
    l.l_quantity,
    l.l_extendedprice,
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
    o.o_orderdate >= DATE '1997-01-01'
    AND o.o_orderdate < DATE '1997-12-31'
    AND l.l_returnflag = 'N'
ORDER BY 
    c.c_custkey, o.o_orderkey;