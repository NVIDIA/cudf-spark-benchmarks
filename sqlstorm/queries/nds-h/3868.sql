WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS revenue_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_available,
        ss.part_count,
        ss.avg_acctbal
    FROM 
        SupplierStats ss
    WHERE 
        ss.avg_acctbal > (SELECT AVG(avg_acctbal) FROM SupplierStats)
)
SELECT 
    c.c_name AS customer_name,
    o.total_orders,
    o.total_spent,
    COALESCE(hs.s_name, 'No Supply') AS supplier_name,
    hs.total_available AS supplier_available,
    hs.part_count AS unique_parts_supplied
FROM 
    OrderStats o
LEFT JOIN 
    customer c ON o.c_custkey = c.c_custkey
LEFT JOIN 
    HighValueSuppliers hs ON hs.total_available > o.total_spent
WHERE 
    o.total_orders > 0
ORDER BY 
    o.total_spent DESC, hs.part_count DESC;
