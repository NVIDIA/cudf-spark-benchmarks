WITH CTE_Suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) as rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s_acctbal) 
            FROM supplier 
            WHERE s_acctbal IS NOT NULL
        )
),
CTE_Parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_retailprice < 50.00
),
CTE_Orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
    HAVING 
        COUNT(l.l_orderkey) > 5
)
SELECT 
    s.s_name,
    s.nation_name,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    o.order_value,
    o.lineitem_count,
    p.comment_length
FROM 
    CTE_Suppliers s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    CTE_Parts p ON ps.ps_partkey = p.p_partkey
JOIN 
    CTE_Orders o ON o.o_orderkey = ps.ps_partkey
WHERE 
    s.rn <= 3 AND 
    p.comment_length > 10
ORDER BY 
    s.nation_name, o.order_value DESC;
