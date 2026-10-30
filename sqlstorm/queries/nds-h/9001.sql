WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_supply_value DESC) AS rank
    FROM 
        RankedSuppliers
    WHERE 
        total_supply_value > (
            SELECT AVG(total_supply_value) 
            FROM RankedSuppliers
        )
)
SELECT 
    c.c_custkey, 
    c.c_name, 
    c.c_address, 
    o.o_orderkey, 
    o.o_orderdate, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    c.c_custkey, c.c_name, c.c_address, o.o_orderkey, o.o_orderdate
ORDER BY 
    revenue DESC
LIMIT 100;