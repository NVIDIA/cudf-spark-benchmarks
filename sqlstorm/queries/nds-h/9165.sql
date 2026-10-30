WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name AS region,
        RANK() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rank_in_region
    FROM 
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 1000000
),
PopularParts AS (
    SELECT 
        li.l_partkey,
        COUNT(DISTINCT li.l_orderkey) AS order_count
    FROM 
        lineitem li
    GROUP BY 
        li.l_partkey
    ORDER BY 
        order_count DESC
    LIMIT 10
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    rs.s_name AS top_supplier,
    rs.region,
    rv.total_value,
    pp.order_count
FROM 
    part p
JOIN 
    HighValueParts rv ON p.p_partkey = rv.ps_partkey
JOIN 
    RankedSuppliers rs ON rs.rank_in_region = 1
JOIN 
    PopularParts pp ON pp.l_partkey = p.p_partkey
WHERE 
    p.p_retailprice > 500
ORDER BY 
    rv.total_value DESC, 
    pp.order_count DESC;
