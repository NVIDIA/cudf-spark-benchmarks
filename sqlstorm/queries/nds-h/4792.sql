WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rank 
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey 
    WHERE 
        s.s_acctbal > 1000
), CustomerStats AS (
    SELECT 
        c.c_custkey, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_spent 
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey 
), NationRegion AS (
    SELECT 
        n.n_name AS nation_name, 
        r.r_name AS region_name, 
        COUNT(DISTINCT c.c_custkey) AS customer_count 
    FROM 
        nation n 
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey 
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey 
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    ns.nation_name, 
    ns.region_name, 
    ns.customer_count, 
    rs.s_name AS supplier_name, 
    rs.s_acctbal AS supplier_balance 
FROM 
    NationRegion ns 
LEFT JOIN 
    RankedSuppliers rs ON ns.customer_count > 10 AND rs.rank = 1 
WHERE 
    ns.customer_count IS NOT NULL 
    AND (rs.s_acctbal IS NULL OR rs.s_acctbal > 5000) 
ORDER BY 
    ns.region_name, 
    ns.nation_name;
