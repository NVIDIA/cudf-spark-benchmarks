WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
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
        s.*,
        ROW_NUMBER() OVER (PARTITION BY s.nation_name ORDER BY s.total_supply_value DESC) AS rn
    FROM 
        SupplierStats s
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.c_acctbal,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    ts.s_name AS top_supplier_name,
    ts.total_supply_value
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    TopSuppliers ts ON ts.rn = 1
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
ORDER BY 
    c.c_custkey, o.o_orderdate;