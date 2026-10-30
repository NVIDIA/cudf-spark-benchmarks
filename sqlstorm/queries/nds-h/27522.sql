WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        n.n_name AS nation_name,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        cs.total_cost AS supplier_cost
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        (
            SELECT 
                l.l_orderkey,
                SUM(ps.ps_supplycost * l.l_quantity) AS total_cost
            FROM 
                lineitem l
            JOIN 
                partsupp ps ON l.l_partkey = ps.ps_partkey
            GROUP BY 
                l.l_orderkey
        ) cs ON o.o_orderkey = cs.l_orderkey
)
SELECT 
    cu.c_custkey,
    cu.c_name,
    cu.o_orderkey,
    cu.o_totalprice,
    cu.o_orderdate,
    ts.s_name AS top_supplier_name,
    ts.total_cost AS supplier_total_cost
FROM 
    CustomerOrders cu
JOIN 
    TopSuppliers ts ON cu.supplier_cost = ts.total_cost
ORDER BY 
    cu.o_orderdate DESC, 
    cu.o_totalprice DESC;
