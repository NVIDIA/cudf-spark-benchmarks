WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
)
SELECT 
    r.r_name, 
    rs.s_name, 
    hvo.o_orderkey, 
    hvo.o_totalprice
FROM 
    RankedSuppliers rs
JOIN 
    region r ON rs.s_suppkey = r.r_regionkey
JOIN 
    HighValueOrders hvo ON hvo.order_rank <= 10
WHERE 
    rs.supplier_rank <= 5
ORDER BY 
    r.r_name, 
    rs.total_supply_cost DESC, 
    hvo.o_totalprice DESC;