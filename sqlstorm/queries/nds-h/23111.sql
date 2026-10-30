WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_by_acctbal
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        pp.rank_by_acctbal
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        RankedSuppliers pp ON ps.ps_suppkey = pp.s_suppkey
    WHERE 
        p.p_retailprice > (SELECT AVG(ps1.ps_supplycost) FROM partsupp ps1 WHERE ps1.ps_partkey = p.p_partkey)
),
OrdersWithDiscount AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_discounted_price,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(COALESCE(l.l_quantity, 0)) AS total_quantity,
    AVG(COALESCE(hvp.p_retailprice, 0)) AS avg_high_value_part_price,
    CASE 
        WHEN SUM(ow.total_discounted_price) > 10000 THEN 'High Volume'
        WHEN SUM(ow.total_discounted_price) IS NULL THEN 'No Sales'
        ELSE 'Regular Volume'
    END AS sales_category
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    HighValueParts hvp ON l.l_partkey = hvp.p_partkey
LEFT JOIN 
    OrdersWithDiscount ow ON o.o_orderkey = ow.o_orderkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND (n.n_name LIKE 'A%' OR n.n_name IS NULL)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    total_quantity DESC NULLS LAST;