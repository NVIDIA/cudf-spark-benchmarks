
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
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
        n.n_name,
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
        COUNT(o.o_orderkey) AS order_count,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        o.o_orderdate,
        c.c_name,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
)

SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.order_count,
    cs.total_spent,
    os.order_total,
    os.o_orderdate,
    ts.s_name AS top_supplier_name,
    ts.total_cost AS top_supplier_cost
FROM 
    CustomerOrders cs
LEFT JOIN 
    OrderDetails os ON cs.c_name = os.c_name
LEFT JOIN 
    TopSuppliers ts ON cs.c_custkey = (
        SELECT 
            MAX(c.c_custkey)
        FROM 
            customer c
        INNER JOIN 
            orders o ON c.c_custkey = o.o_custkey
        WHERE 
            o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    )
WHERE 
    (cs.total_spent > 1000 OR os.total_quantity > 50)
ORDER BY 
    cs.total_spent DESC, os.o_orderdate;
