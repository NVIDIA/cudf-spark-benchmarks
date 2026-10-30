WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown Size'
            WHEN p.p_size BETWEEN 1 AND 10 THEN 'Small'
            WHEN p.p_size BETWEEN 11 AND 20 THEN 'Medium'
            ELSE 'Large'
        END AS size_category
    FROM 
        part p
),
AggregatedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supplycost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
CustomerOrderRankings AS (
    SELECT 
        o.o_custkey,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_custkey, o.o_orderkey
),
NestedAggregates AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(co.total_order_value), 0) AS total_spent,
        AVG(CASE WHEN co.order_rank = 1 THEN total_order_value END) AS avg_high_order_value
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrderRankings co ON c.c_custkey = co.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(CASE WHEN ns.total_spent > 0 THEN ns.total_spent END) AS total_revenue,
    AVG(ns.avg_high_order_value) AS avg_highest_order_value
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    NestedAggregates ns ON n.n_nationkey = ns.c_custkey
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY 
    total_revenue DESC NULLS LAST
LIMIT 10 OFFSET 5;
