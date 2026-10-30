WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
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
        s.s_suppkey,
        s.s_name,
        ss.total_available_quantity,
        ss.total_supply_cost,
        DENSE_RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS rank
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_available_quantity,
    ts.total_supply_cost,
    o.o_orderkey,
    o.o_orderdate,
    l.l_quantity,
    l.l_extendedprice
FROM 
    TopSuppliers ts
JOIN 
    partsupp ps ON ts.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    ts.rank <= 10 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    ts.total_supply_cost DESC, 
    o.o_orderdate ASC;