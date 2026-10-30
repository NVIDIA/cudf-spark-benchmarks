WITH CTE_Supplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_comment IS NOT NULL)
    GROUP BY 
        s.s_suppkey, s.s_name
),
CTE_Orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'F'
)
SELECT 
    p.p_name,
    r.r_name AS region_name,
    COUNT(DISTINCT li.l_orderkey) AS total_orders,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS revenue_rank
FROM 
    part p
LEFT JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
LEFT JOIN 
    supplier s ON li.l_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    (p.p_size IS NULL OR p.p_size > 50)
    AND r.r_name NOT IN (SELECT r_name FROM region WHERE r_comment LIKE '%North%')
    AND EXISTS (
        SELECT 1 
        FROM CTE_Supplier cs 
        WHERE cs.s_suppkey = s.s_suppkey
        AND cs.total_supply_cost > 1000.00
    )
GROUP BY 
    p.p_partkey, p.p_name, r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC, revenue_rank ASC
LIMIT 10;
