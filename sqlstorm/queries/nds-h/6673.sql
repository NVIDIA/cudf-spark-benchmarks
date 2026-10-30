
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        * 
    FROM 
        RankedSuppliers 
    WHERE 
        supplier_rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        COALESCE(l.l_quantity, 0) AS total_quantity,
        l.l_partkey
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
)
SELECT 
    ts.nation_name,
    c.c_name,
    SUM(co.total_quantity) AS total_ordered_quantity,
    SUM(co.o_totalprice) AS total_spent,
    COUNT(DISTINCT co.o_orderkey) AS total_orders
FROM 
    TopSuppliers ts
JOIN 
    partsupp ps ON ts.s_suppkey = ps.ps_suppkey
JOIN 
    CustomerOrders co ON ps.ps_partkey = co.l_partkey
JOIN 
    customer c ON co.c_custkey = c.c_custkey
GROUP BY 
    ts.nation_name, c.c_name
ORDER BY 
    ts.nation_name, total_spent DESC;
