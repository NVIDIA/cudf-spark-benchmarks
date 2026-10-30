
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_per_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        s.*, 
        n.n_name
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.s_suppkey = n.n_nationkey
    WHERE 
        s.rank_per_nation = 1
),
OrderData AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        COUNT(DISTINCT li.l_orderkey) AS line_count,
        CUME_DIST() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount))) AS order_profit_ratio
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    COALESCE(SUM(T.total_sales), 0) AS total_sales,
    SUM(CASE WHEN s.rank_per_nation IS NOT NULL THEN 1 ELSE 0 END) AS supplier_count,
    MAX(T.order_profit_ratio) AS max_profit_ratio
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    TopSuppliers s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    OrderData T ON ps.ps_partkey = T.o_orderkey
WHERE 
    p.p_size > 10 AND 
    p.p_retailprice BETWEEN 100.00 AND 500.00 AND 
    (p.p_comment LIKE '%fragile%' OR p.p_comment IS NULL)
GROUP BY 
    ps.ps_partkey, p.p_name
HAVING 
    COALESCE(SUM(T.total_sales), 0) > 1000
ORDER BY 
    total_sales DESC, supplier_count ASC;
