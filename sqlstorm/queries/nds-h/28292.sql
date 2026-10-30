WITH SupplierParts AS (
    SELECT 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TopSupplierParts AS (
    SELECT 
        sp.s_suppkey, sp.s_name, sp.p_partkey, sp.p_name, sp.ps_supplycost
    FROM 
        SupplierParts sp
    WHERE 
        sp.rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)

SELECT 
    ts.s_name AS supplier_name, 
    ts.p_name AS part_name, 
    co.c_name AS customer_name, 
    COALESCE(co.total_spent, 0) AS customer_total_spent
FROM 
    TopSupplierParts ts
LEFT JOIN 
    CustomerOrders co ON ts.s_suppkey = co.c_custkey
ORDER BY 
    total_spent DESC, supplier_name, part_name;
