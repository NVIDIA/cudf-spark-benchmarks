WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
    ORDER BY 
        supplier_cost DESC
    LIMIT 10
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.total_available_quantity,
    ts.s_suppkey,
    ts.s_name,
    cos.c_custkey,
    cos.c_name,
    cos.order_count,
    cos.total_spent
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON rp.total_supply_cost > 10000 AND ts.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
JOIN 
    CustomerOrderStats cos ON cos.total_spent > 5000
ORDER BY 
    rp.total_available_quantity DESC, cos.total_spent DESC;
