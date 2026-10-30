WITH RecursiveCTE AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        SUM(o.o_totalprice) > 100000
), 
OrderWithRowNum AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
), 
FilteredOrders AS (
    SELECT 
        o.*,
        CASE 
            WHEN o.o_totalprice > 50000 THEN 'High Value'
            ELSE 'Regular'
        END AS order_type
    FROM 
        OrderWithRowNum o
    WHERE 
        o.rn <= 10
)
SELECT 
    c.c_name, 
    c.c_acctbal, 
    c.c_mktsegment, 
    r.r_name AS region_name, 
    rc.total_revenue,
    fo.order_type,
    COALESCE(NULLIF(fo.o_totalprice, 0), ps.ps_supplycost) AS effective_price
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RecursiveCTE rc ON n.n_nationkey = rc.n_nationkey
LEFT JOIN 
    FilteredOrders fo ON c.c_custkey = fo.o_orderkey
LEFT JOIN 
    partsupp ps ON ps.ps_partkey IN (
        SELECT p.p_partkey 
        FROM part p 
        WHERE p.p_size > 10 AND p.p_retailprice < 100
    )
WHERE 
    c.c_acctbal IS NOT NULL 
    AND r.r_name IS NOT NULL 
ORDER BY 
    total_revenue DESC, 
    c.c_name;