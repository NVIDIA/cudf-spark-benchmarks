
WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal, o.o_orderkey, o.o_totalprice, o.o_orderstatus
),
region_stats AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    COALESCE(o.o_totalprice, 0) AS order_total,
    COALESCE(rs.total_cost, 0) AS supplier_cost,
    rg.r_name AS region_name,
    cs.c_name AS customer_name,
    cs.lineitem_count,
    ROW_NUMBER() OVER (PARTITION BY rg.r_name ORDER BY COALESCE(o.o_totalprice, 0) DESC) AS order_rank
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    ranked_suppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rn = 1
LEFT JOIN 
    (SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS o_totalprice
     FROM 
        orders o
     JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
     GROUP BY 
        o.o_orderkey) o ON ps.ps_partkey = o.o_orderkey
LEFT JOIN 
    customer_orders cs ON o.o_orderkey = cs.o_orderkey
LEFT JOIN 
    region_stats rg ON (SELECT COUNT(*) FROM region) > 0 
WHERE 
    (p.p_size * ps.ps_availqty > (SELECT AVG(p_size) FROM part) OR 
    ps.ps_supplycost < 50.00) 
    AND p.p_retailprice IS NOT NULL
ORDER BY 
    region_name, order_total DESC, supplier_cost ASC
LIMIT 10 OFFSET 5;
