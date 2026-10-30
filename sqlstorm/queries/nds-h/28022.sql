
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartStats AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name
)
SELECT 
    ps.p_partkey AS part_key,
    ps.total_availqty,
    ps.avg_supplycost,
    ps.unique_suppliers,
    cs.c_name AS customer_name,
    cs.total_spent,
    cs.order_count,
    rs.s_name AS top_supplier
FROM 
    PartStats ps
JOIN 
    CustomerOrders cs ON ps.p_partkey = cs.o_orderkey
JOIN 
    RankedSuppliers rs ON rs.rank = 1 AND ps.unique_suppliers > 0
ORDER BY 
    ps.total_availqty DESC, cs.total_spent DESC;
