WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
part_supplier_summary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
product_lines AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice * 0.9 AS discounted_price
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 5 AND 15
    UNION ALL
    SELECT 
        p.p_partkey,
        CONCAT(p.p_name, ' (Special Edition)') AS p_name,
        p.p_retailprice * 1.1 AS discounted_price
    FROM 
        part p
    WHERE 
        p.p_comment LIKE '%Special%'
),
outlier_orders AS (
    SELECT 
        o.o_orderkey,
        COALESCE(SUM(l.l_discount), 0) AS total_discounted
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_discount) > (SELECT AVG(l2.l_discount) FROM lineitem l2 WHERE l2.l_shipdate > cast('1998-10-01' as date) - INTERVAL '1 year')
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    ps.total_supply_value,
    COALESCE(out.total_discounted, 0) AS total_discounted,
    pl.p_name,
    pl.discounted_price
FROM 
    ranked_orders r
LEFT JOIN 
    part_supplier_summary ps ON r.o_orderkey % 100 = ps.ps_partkey 
JOIN 
    product_lines pl ON pl.p_partkey = r.o_orderkey % 100
LEFT JOIN 
    outlier_orders out ON r.o_orderkey = out.o_orderkey
WHERE 
    r.order_rank = 1 
    AND (out.total_discounted IS NULL OR out.total_discounted > 100)
ORDER BY 
    r.o_orderdate DESC,
    total_supply_value DESC NULLS LAST
LIMIT 50;