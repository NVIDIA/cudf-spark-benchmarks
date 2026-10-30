
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice >= (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_container IS NOT NULL)
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT MAX(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey IS NOT NULL)
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationCounts AS (
    SELECT 
        n.n_name, 
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
        o.o_orderdate,
        DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_discount) < 0.1
)
SELECT 
    np.n_name,
    cnt.customer_count,
    rp.p_name AS top_part,
    COALESCE(fs.total_supply_cost, 0) AS total_supplier_cost,
    os.total_revenue
FROM 
    NationCounts cnt
JOIN 
    nation np ON cnt.n_name = np.n_name
LEFT JOIN 
    RankedParts rp ON cnt.customer_count > 10 AND rp.brand_rank = 1
LEFT JOIN 
    FilteredSuppliers fs ON fs.s_suppkey = (SELECT s_suppkey FROM supplier ORDER BY s_acctbal DESC LIMIT 1)
LEFT JOIN 
    OrderStats os ON os.total_revenue > 10000
ORDER BY 
    cnt.customer_count DESC, 
    fs.total_supply_cost ASC
LIMIT 50 OFFSET 25;
