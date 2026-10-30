WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        s.s_suppkey, s.s_name
), 
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_custkey, c.c_name
), 
QualifiedSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_available,
        ss.avg_supply_cost,
        ss.part_count,
        ROW_NUMBER() OVER (PARTITION BY ss.part_count ORDER BY ss.avg_supply_cost DESC) AS rn
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_available > 500
)

SELECT 
    cs.c_name AS customer_name,
    cs.order_count,
    cs.total_spent,
    qs.s_name AS supplier_name,
    qs.avg_supply_cost,
    qs.total_available
FROM 
    CustomerOrderStats cs
LEFT JOIN 
    QualifiedSuppliers qs ON cs.order_count > 5
WHERE 
    qs.rn = 1
ORDER BY 
    cs.total_spent DESC, 
    qs.avg_supply_cost ASC;