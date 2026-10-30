
WITH supplier_info AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name LIKE '%land%'
    AND 
        s.s_acctbal IS NOT NULL
),
customer_orders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) IS NULL OR COUNT(o.o_orderkey) > 5
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000 AND COUNT(DISTINCT l.l_partkey) < 10
),
aggregate_supp AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    pi.p_partkey,
    pi.p_name,
    pi.p_retailprice,
    si.s_name AS supplier_name,
    co.total_orders,
    co.total_spent,
    ls.total_value AS order_value,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        WHEN co.total_spent > 1000 THEN 'High Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM 
    part pi
LEFT JOIN 
    aggregate_supp g ON pi.p_partkey = g.ps_partkey
LEFT JOIN 
    supplier_info si ON g.ps_partkey = si.s_suppkey
JOIN 
    customer_orders co ON si.s_suppkey = co.c_custkey
JOIN 
    lineitem_summary ls ON co.c_custkey = ls.l_orderkey
WHERE 
    pi.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_brand NOT IN ('BrandX', 'BrandY'))
    AND 
    (si.rank_acctbal < 10 OR si.rank_acctbal IS NULL)
ORDER BY 
    pi.p_retailprice DESC, si.s_name;
